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


fn (self App) add_app(app app_db.App){
	// Todo: Check 
	self.db.app.add(app)
}

fn (self App) list_apps() []app_db.App{
	return self.db.app.find_all()
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

fn (self App) download_github_release(project github.Project, app app_db.App, folder string){
	releases := project.get_releases(1)
	if releases.len>0 {
		last_release := releases.first()
		if asset := search_asset[github.Asset](last_release.assets, app.regex) {
			println(asset)
			path := os.join_path(folder, asset.name)
			project.download_file(asset.browser_download_url, path)
			self.db.app.update_last_download(app.id, asset.created_at)
		}
	} else {
		println("Not found releases for project ${project.owner}/${project.name}")
	}
}


fn (self App) download_github_artifact(project github.Project, app app_db.App, folder string){
	workflow_runs := project.get_workflows()
	// todo: have some configuration to point to the branch
	filtered_workflows := workflow_runs.filter(it.head_branch in ['master', 'main'] && it.conclusion == 'success')
	if filtered_workflows.len >1 {
		first_workflow := filtered_workflows.first()
		artifacts := project.get_artifacts(first_workflow.id)
		if artifact := search_asset[github.Artifact](artifacts, app.regex) {
			println(artifact)
			path := os.join_path(folder, artifact.name)
			project.download_file(artifact.archive_download_url, path)
			self.db.app.update_last_download(app.id, artifact.created_at)
		} else {
			println("No artifact found for ${app}")
		}
	} else {
		println('No workflow found pointing to master or main')
	}
}

fn (self App) download(app_name string, folder string){
	if app := self.db.app.find_by_name(app_name) {	
		project := github.Project{
			owner: app.owner
			name: app.project
			api_token: self.config.github_token
		}
		match app.typ {
			.gh_release{
				self.download_github_release(project, app, folder)
			}
			.gh_artifact{
				self.download_github_artifact(project, app, folder)
			}
		}
	} else {
		println('Application name "${app_name}" not found')
	}
}