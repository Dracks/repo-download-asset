module main

import net.http
import json
import regex
import app_db
import config

struct GhApp {
	name         string
	owner        string
	project      string
	last_release string
	regex        string
}

const vs_codium = GhApp{
	owner: 'VSCodium'
	project: 'vscodium'
	regex: '^.*x86_64.rpm$'
}

struct GhReleaseAsset {
	url                  string
	browser_download_url string
	name                 string
	content_type         string
}

struct GhReleaseResponse {
	url    string
	assets []GhReleaseAsset
}

fn old_search_asset(assets []GhReleaseAsset) ?GhReleaseAsset {
	re := regex.regex_opt(vs_codium.regex) or { panic(err) }
	filtered_assets := assets.filter(re.matches_string(it.name))
	println(filtered_assets)
	if filtered_assets.len == 1 {
		return filtered_assets.first()
	} else if filtered_assets.len == 0 {
		return none
	}
	panic('Found more than one asset ${filtered_assets.len}')
}

fn download_asset(asset GhReleaseAsset) {
	http.download_file(asset.browser_download_url, asset.name) or { panic(err) }
}

fn main_old() {
	r := http.get('https://api.github.com/repos/${vs_codium.owner}/${vs_codium.project}/releases?per_page=1') or {
		panic(err)
	}

	gh_response := json.decode([]GhReleaseResponse, r.body) or { panic(err) }

	if gh_asset := old_search_asset(gh_response.first().assets) {
		download_asset(gh_asset)
	}
}

fn main() {
	config_dir := config.get_dir()
	db := app_db.init(config_dir)
	conf := config.load()
	app := App{
		db: db
		config: conf
	}
	execute_cli(app)
}
