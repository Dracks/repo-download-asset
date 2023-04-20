module github

import net.http
import json

struct Asset {
	url string
	browser_download_url string
	name string
	content_type string
	created_at string
}

struct GhReleaseResponse{
	url string
	assets []Asset
}

fn (self Project) get_releases(page_size ?int) []GhReleaseResponse{
	r := http.get("https://api.github.com/repos/${self.owner}/${self.project}/releases?per_page=${page_size}") or {panic(err)}

	return json.decode([]GhReleaseResponse, r.body) or { panic(err) }
}