module main

import cli { Command, Flag }
import os
import app_db

const (
	cli_str_gh_release  = 'release'
	cli_str_gh_artifact = 'artifact'
)

fn parse_add_app(cmd Command) app_db.App {
	mut project := cmd.flags.get_string('project') or { '' }
	mut owner := cmd.flags.get_string('owner') or { '' }
	url := cmd.flags.get_string('url') or { '' }

	regex := cmd.flags.get_string('regex') or { '' }
	name := cmd.flags.get_string('name') or { '' }
	typ_str := cmd.flags.get_string('type') or { panic('type is required') }

	typ := match typ_str {
		cli_str_gh_release {
			app_db.AppType.gh_release
		}
		cli_str_gh_artifact {
			app_db.AppType.gh_artifact
		}
		else {
			panic('Invalid application type, use "${cli_str_gh_release}" or "${cli_str_gh_artifact}"')
		}
	}

	if url.len > 0 {
		if project.len > 0 || owner.len > 0 {
			panic('Use the url or project and owner parameters, but you cannot combine them')
		}
		split_url := url.split('/')
		println(split_url)
		if split_url.len < 5 {
			panic('Please use the github url of the repo, like https://github.com/jpochyla/psst')
		}
		owner = split_url[3]
		project = split_url[4]
	}

	return app_db.App{
		name: name
		regex: regex
		project: project
		owner: owner
		typ: typ
	}
}

fn print_app(app app_db.App) {
	type_str := match app.typ {
		.gh_release { 'Github Release' }
		.gh_artifact { 'Github Artifact' }
	}
	println('${app.name}:${app.owner}/${app.project}\t\t${type_str}')
	println('\tLast release check: ${app.latest_release}\t\tLast build downloaded: ${app.last_download}')
}

fn execute_cli(app &App) {
	mut cli_exec := Command{
		name: 'Repo download artifacts'
		description: 'Download your favorite applications directly from the repository releases'
		commands: [
			Command{
				name: 'add'
				description: 'Add an application in the list'
				execute: fn [app] (cmd Command) ! {
					new_app := parse_add_app(cmd)
					app.add_app(new_app) or { println(err) }
				}
				flags: [
					Flag{
						flag: cli.FlagType.string
						name: 'project'
						abbrev: 'p'
						description: 'project name of the project, second parameter in github url'
					},
					Flag{
						flag: cli.FlagType.string
						name: 'owner'
						abbrev: 'o'
						description: 'owner of the project, first parameter in github url'
					},
					Flag{
						flag: cli.FlagType.string
						name: 'url'
						abbrev: 'u'
						description: 'Url of github to be able to parse the project and the owner'
					},
					Flag{
						flag: cli.FlagType.string
						required: true
						name: 'name'
						abbrev: 'n'
						description: 'A simmple name to identify the application'
					},
					Flag{
						flag: cli.FlagType.string
						required: true
						name: 'regex'
						abbrev: 'r'
						description: 'regex to filter the file to download'
					},
					Flag{
						flag: cli.FlagType.string
						name: 'type'
						abbrev: 't'
						default_value: [cli_str_gh_release]
						description: 'define if it\'s a github release or an action artifact use: "${cli_str_gh_release}" or "${cli_str_gh_artifact}"'
					},
				]
			},
			Command{
				name: 'config'
				description: 'Set configuration'
				execute: fn [app] (cmd Command) ! {
					mut config := app.config
					if github_token := cmd.flags.get_string('github_token') {
						config.github_token = github_token
					}
					config.write_file()
				}
				flags: [
					Flag{
						flag: cli.FlagType.string
						name: 'github_token'
					},
				]
			},
			Command{
				name: 'delete'
				description: 'Delete an application from the list'
				required_args: 1
				execute: fn [app] (cmd Command) ! {
					app_name := cmd.args.first()
					if db_app := app.get_app(app_name) {
						println('Are you sure you wish to delete the following app')
						print_app(db_app)
						confirmation := os.input('Repeat the app name>')
						if app_name == confirmation {
							app.delete_app(db_app)
							println('App deleted')
						} else {
							println("Confirmation doesn't match, aborting")
						}
					} else {
						println('No app ${app_name} found')
					}
				}
			},
			Command{
				name: 'download'
				description: 'Download the last application (arg0 is the app name)'
				execute: fn [app] (cmd Command) ! {
					app_name := cmd.args.first()
					folder := cmd.flags.get_string('folder') or { './downloads' }
					app.download(app_name, folder)
				}
				required_args: 1
				flags: [
					Flag{
						flag: cli.FlagType.string
						name: 'folder'
						abbrev: 'f'
						required: false
						description: 'Folder to download the app'
						default_value: ['./downloads']
					},
				]
			},
			Command{
				name: 'list'
				description: 'List the applications registered in the database'
				execute: fn [app] (cmd Command) ! {
					apps := app.list_apps()
					for registered_app in apps {
						print_app(registered_app)
					}
				}
			},
			Command{
				name: 'update'
				description: 'Update the last version available'
				execute: fn [app] (cmd Command) ! {
					if cmd.args.len > 0 {
						for app_name in cmd.args {
							app.update_app_name(app_name)
						}
					} else {
						app.update_all()
					}
				}
			},
		]
	}

	cli_exec.setup()
	cli_exec.parse(os.args)
}
