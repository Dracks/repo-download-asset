module github

import net.http
import json

pub struct Asset {
pub:
	url                  string
	browser_download_url string
	name                 string
	content_type         string
	created_at           string
}

pub struct GhReleaseResponse {
pub:
	url    string
	assets []Asset
}

pub fn (self Project) get_releases(page_size ?int) []GhReleaseResponse {
	r := http.get('https://api.github.com/repos/${self.owner}/${self.name}/releases?per_page=${page_size}') or {
		panic(err)
	}

	return json.decode([]GhReleaseResponse, r.body) or { panic(err) }
}
