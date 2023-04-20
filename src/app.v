module main

import app_db
import github 


struct App {
	db app_db.Db
}


fn (self App) add_app(app app_db.App){
	// Todo: Check 
	self.db.app.add(app)
}

fn (self App) list_apps() []app_db.App{
	return self.db.app.find_all()
}

fn (self App) download(app_name string, folder string){
	if app := self.db.app.find_by_name(app_name) {	
		project := github.Project{
			owner: app.owner
			project: app.project
		}
		match app.typ {
			.gh_release{
				
			}
			.gh_artifact{}
		}
	}
}