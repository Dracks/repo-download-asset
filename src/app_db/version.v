module app_db

import os
import db.sqlite

struct DbVersion {
	id int [primary]
}

const (
	current = 1
	no_version = 0
)

pub struct Db {
pub:
	app AppDao
}

fn get_config_dir() string {
	config_path := os.config_dir() or { panic(err) }
	real_path := os.join_path(os.expand_tilde_to_home(config_path), 'repo-release-downloader')
	os.mkdir_all(real_path)  or { panic(err) }
	return real_path
}

fn get_version(db sqlite.DB) int {
	versions := sql db {
		select from DbVersion
	} or { panic(err) }

	if versions.len >1 {
		panic('Invalid number of versions row in db')
	} else if versions.len == 1{
		return versions.first().id
	}
	return no_version
}

fn check_and_migrate(db sqlite.DB){
	db_version := get_version(db)
	current_version := DbVersion{id: current}

	match db_version {
		no_version {
			sql db {
				create table AppTable
				insert current_version into DbVersion
			} or { panic(err) }
		}
		current {}
		else {
			panic('Invalid db_version ${db_version} in database')
		}
	}
}


pub fn init() Db{
	db := sqlite.connect(os.join_path(get_config_dir(),'db.sqlite')) or { panic(err) }

	sql db {
		create table DbVersion
	} or { panic(err) }

	check_and_migrate(db)

	return Db{
		app: AppDao{db: db}
	}
}