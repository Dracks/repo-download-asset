module github 

import net.http
import json

pub struct Artifact {
	id int
	name string
	archive_download_url string
	created_at string
}

struct ArtifactList {
	total_count int
	artifacts []Artifact
}


fn (self Project) get_artifacts(workflowId int) []Artifact{
	response := http.get("https://api.github.com/repos/${self.owner}/${self.project}/actions/runs") or { panic(err) }
	artifact_list := json.decode(ArtifactList, response.body) or { panic(err) }
	return artifact_list.artifacts
}