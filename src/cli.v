module main

import cli { Command, Flag }
import os
import app_db


fn parse_add_app(cmd Command) app_db.App{
	mut project := cmd.flags.get_string('project') or { '' }
	mut owner := cmd.flags.get_string('owner') or { '' }
	url := cmd.flags.get_string('url') or { '' }

	regex := cmd.flags.get_string('regex') or { '' }
	name := cmd.flags.get_string('name') or { '' }

	if url.len>0 {
		if project.len>0 || owner.len>0 {
			panic('Use the url or project and owner parameters, but you cannot combine them')
		}
		split_url := url.split('/')
		println(split_url)
		if split_url.len<5 {
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
		typ: .gh_release
	}
}

fn print_app(app app_db.App){
	type_str := match app.typ{
		.gh_release { 'Github Release' }
		.gh_artifact { 'Github Artifact' }
	}
	println("${app.name}\t\t${type_str}")
	println("\tLast build downloaded: ${app.last_download}\t\tLast release check: ${app.latest_release}")

}

fn execute_cli(app App) {
	mut cli_exec := Command{
		name: 'Repo download artifacts'
		description: 'Download your favorite applications directly from the repository releases'
		commands: [
			Command{
				name: 'add'
				description: 'Add an application in the list'
				execute: fn [app] (cmd Command) ! {
					new_app:= parse_add_app(cmd)
					app.add_app(new_app)
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
						name: 'name'
						abbrev: 'n'
						description: 'A simmple name to identify the application'
					},
					Flag{
						flag: cli.FlagType.string
						name: 'regex'
						abbrev: 'r'
						description: 'regex to filter the file to download'
					},
					// Todo add the type of application
				]
			},
			Command{
				name: 'list'
				description: 'List the applications registered in the database'
				execute: fn [app] (cmd Command)!{
					apps := app.list_apps()
					for registered_app in apps {
						print_app(registered_app)
					}
				}
			}
			Command{
				name: 'download'
				description: 'Download the last application'
				execute: fn [app] (cmd Command)!{
					app_name := cmd.flags.get_string('name') or {panic('Name is required')}
					app.download(app_name, '.')
				}
				flags: [
					Flag{
						flag: cli.FlagType.string
						name: 'name'
						abbrev: 'n'
						required: true
						description: 'App name to download'
					}
				]
			}
		]
	}

	cli_exec.setup()
	cli_exec.parse(os.args)
}
