module app_db

import db.sqlite

pub enum AppType {
	gh_release
	gh_artifact
}

const (
	gh_release_db=1
	gh_artifact_db=2
)

pub struct App {
pub:
	id int 
	name string [required]
	owner string [required]
	project string [required]
	last_download string
	latest_release string
	regex string [required]
	typ AppType [required]
}

[table: 'App']
struct AppTable {
	id int [sql: serial; primary]
	name string [required; sql_type: 'varchar(255)']
	owner string [required; sql_type: 'varchar(255)']
	project string [required; sql_type: 'varchar(255)']
	last_download string
	latest_release string
	regex string [required; sql_type: 'varchar(255)']
	typ int [required; sql_type: 'INTEGER']
}

struct AppDao {
	db sqlite.DB
}

fn convert_to_public_app(app AppTable) App {
	typ := match app.typ{
		gh_release_db { AppType.gh_release }
		gh_artifact_db { AppType.gh_artifact }
		else {
			panic('Invalid type found in the db ${app.typ}')
		}
	}
	return App{
		id: app.id
		name: app.name
		owner: app.owner
		project: app.project
		last_download: app.last_download
		latest_release: app.latest_release
		regex: app.regex
		typ: typ
	}
}

pub fn (dao AppDao) add(app App){
	app_table := AppTable{
		name: app.name
		owner: app.owner
		project: app.project
		last_download: app.last_download
		latest_release: app.latest_release
		regex: app.regex
		typ: match app.typ {
			.gh_release { gh_release_db }
			.gh_artifact { gh_artifact_db }
		}
	}
	sql dao.db {
		insert app_table into AppTable
	} or { panic(err) }
}

pub fn (dao AppDao) find_all() []App {
	apps := sql dao.db{
		select from AppTable
	} or { panic(err) }
	return apps.map(convert_to_public_app(it))
}

pub fn (dao AppDao) find_by_name(app_name string) ?App {
	apps := sql dao.db{
		select from AppTable where name == app_name
	} or { panic(err) }
	if apps.len== 1 {
		return convert_to_public_app(apps.first())
	} else if apps.len == 0 {
		return none
	} else {
		panic('found ${apps.len} apps in db with name ${app_name}')
	}
}

pub fn (dao AppDao) update_last_download(app_id int, download_str string){
	sql dao.db{
		update AppTable set last_download = download_str where id == app_id
	} or { panic(err) }
}