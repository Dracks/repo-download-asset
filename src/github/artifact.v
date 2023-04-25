module github 

import net.http
import json

pub struct Artifact {
pub:
	id i64
	name string
	archive_download_url string
	created_at string
}

struct ArtifactList {
	total_count int
	artifacts []Artifact
}


pub fn (self Project) get_artifacts(workflowId i64) []Artifact{
	response := http.get("https://api.github.com/repos/${self.owner}/${self.name}/actions/runs/${workflowId}/artifacts") or { panic(err) }
	artifact_list := json.decode(ArtifactList, response.body) or { panic(err) }
	return artifact_list.artifacts
}