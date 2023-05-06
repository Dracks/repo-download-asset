module main

import ui
import app_db

struct Window {
	app App [required]
}



fn (self Window) list_apps_grid() ui.Widget {
	apps := self.app.list_apps()
	header := ["Name", "Last download", "Last version"]
	rows := apps.map(fn (app app_db.App) []string {
		return [app.name, app.last_download, app.latest_release]
	})

	return ui.grid(header: header, body: rows, width: 790, height: 690)
}


fn (self Window) open_main() {
	window := ui.window(
		width: 800
		height: 600
		title: 'Github Download Apps'
		children: [ui.row(
				margin: ui.Margin{5, 5, 5, 5}
				children: [
					self.list_apps_grid(),
				]
			),
		]
	)
	ui.run(window)
}


fn execute_window(app &App){
	println(app)
	window := Window{
		app: app
	}
	window.open_main()
}
