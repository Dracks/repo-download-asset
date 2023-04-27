module main

import os
import app_db
import github 
import regex
import config


struct App {
	db app_db.Db
	config config.Config
}

[inline]
fn (self App) get_project(app app_db.App) github.Project{
	return github.Project{
		owner: app.owner
		name: app.project
		api_token: self.config.github_token
	}
}
fn (self App) add_app(app app_db.App) ! {
	println(app)
	project := self.get_project(app)
	match app.typ{
		.gh_release{
			if asset := self.get_github_asset(project, app){
				self.db.app.add(app_db.App{
					...app
					latest_release: asset.created_at
				})
			} else {
				return error('Asset not found')
			}
		}
		.gh_artifact{
			if artifact := self.get_github_artifact(project, app){
				self.db.app.add(app_db.App{
					...app
					latest_release: artifact.created_at
				})
			} else {
				return error('Artifact not found')
			}
		}
	}
	
}

fn (self App) list_apps() []app_db.App{
	return self.db.app.find_all()
}

fn (self App) get_app(app_name string) ?app_db.App {
	return self.db.app.find_by_name(app_name)
}

fn (self App) delete_app(app app_db.App) {
	self.db.app.delete(app.id)
}

fn search_asset[T](assets []T, regex_str string) ?T{
	re := regex.regex_opt(regex_str) or { panic(err)}
	filtered_assets := assets.filter(re.matches_string(it.name))
	if filtered_assets.len == 1{
		return filtered_assets.first()
	} else if filtered_assets.len ==0 {
		return none
	}
	panic('Found more than one asset ${filtered_assets.len}')
}


fn (self App) get_github_asset(project github.Project, app app_db.App) ?github.Asset {
	releases := project.get_releases(1)
	if releases.len>0 {
		last_release := releases.first()
		return search_asset[github.Asset](last_release.assets, app.regex)
	} else {
		println("Not found releases for project ${project.owner}/${project.name}")
	}
	return none
}

fn (self App) get_github_artifact(project github.Project, app app_db.App) ?github.Artifact {
	workflow_runs := project.get_workflows()
	// todo: have some configuration to point to the branch
	filtered_workflows := workflow_runs.filter(it.head_branch in ['master', 'main'] && it.conclusion == 'success')
	if filtered_workflows.len >1 {
		first_workflow := filtered_workflows.first()
		artifacts := project.get_artifacts(first_workflow.id)
		return search_asset[github.Artifact](artifacts, app.regex)
	} else {
		println('No workflow found pointing to master or main')
	}
	return none
}

fn (self App) download(app_name string, folder string){
	if app := self.db.app.find_by_name(app_name) {	
		project := self.get_project(app)
		match app.typ {
			.gh_release {
				if asset := self.get_github_asset(project, app) {
					path := os.join_path(folder, asset.name)
					self.db.app.update_latest(app.id, asset.created_at)
					project.download_file(asset.browser_download_url, path)
					self.db.app.update_last_download(app.id, asset.created_at)
				} else {
					println('No asset found for ${app}')
				}
			}
			.gh_artifact {
				if artifact := self.get_github_artifact(project, app) {
					path := os.join_path(folder, artifact.name)
					self.db.app.update_latest(app.id, artifact.created_at)
					project.download_file(artifact.archive_download_url, path)
					self.db.app.update_last_download(app.id, artifact.created_at)
				}  else {
					println('No artifact found for ${app}')
				}
			}
		}
	} else {
		println('Application name "${app_name}" not found')
	}
}

fn (self App) update_app(app app_db.App) ! {
	project := self.get_project(app)
	match app.typ{
		.gh_release{
			if asset := self.get_github_asset(project, app){
				self.db.app.update_latest(app.id, asset.created_at)
			} else {
				return error('Asset not found')
			}
		}
		.gh_artifact{
			if artifact := self.get_github_artifact(project, app){
				self.db.app.update_latest(app.id, artifact.created_at)
			} else {
				return error('Artifact not found')
			}
		}
	}
}

fn (self App) update_app_name(app_name string){
	if app := self.db.app.find_by_name(app_name){
		self.update_app(app) or {
			println('Something happened ${err}')
		}
	}
}

fn (self App) update_all(){
	apps := self.db.app.find_all()
	for app in apps {
		self.update_app(app) or {
			println('Something happened with app ${app.name}: ${err}')
		}
	}
}
