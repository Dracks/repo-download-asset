module config

import toml
import os

const (
	config_file_name = 'config'
	github_token_key='gh_token'
)


pub fn get_dir() string {
	config_path := os.config_dir() or { panic(err) }
	real_path := os.join_path(os.expand_tilde_to_home(config_path), 'repo-release-downloader')
	os.mkdir_all(real_path)  or { panic(err) }
	return real_path
}

pub struct Config {
pub mut:
	github_token string
}

pub fn (mut self Config) from_toml(any toml.Any) {
	mp := any.as_map()
	self.github_token = mp[github_token_key] or { toml.Any('') }.string()
}

pub fn (self Config) to_toml() string {
	mut mp := map[string]toml.Any{}
	mp[github_token_key] = toml.Any(self.github_token)
	return mp.to_toml()
}

pub fn load() Config {
	config_path := os.join_path(get_dir(), config_file_name)
	if os.exists(config_path) {
		config_raw := os.read_file(config_path) or { panic(err)}
		return toml.decode[Config](config_raw) or { panic(err)}
	}
	return Config{}
}

pub fn (self Config) write_file() {
	config_path := os.join_path(get_dir(), config_file_name)
	config_raw := toml.encode[Config](self)
	os.write_file(config_path, config_raw) or { panic(err) }
}

