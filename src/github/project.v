module github

import net.http
import os

pub struct Project {
pub:
	owner     string [required]
	name      string [required]
	api_token string
}

pub fn (self Project) download_file(url string, path string) {
	mut header := http.Header{}
	header.set(.authorization, 'Bearer ${self.api_token}')
	s := http.fetch(
		method: .get
		url: url
		header: header
	) or { panic(err) }
	if s.status() != .ok {
		panic('received http code ${s.status_code}')
	}
	$if debug_http ? {
		println('http.download_file saving ${s.body.len} bytes')
	}
	os.write_file(path, s.body) or { panic(err) }
}
