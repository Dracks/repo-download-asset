module github

import net.http
import json

pub struct Workflow {
	id int
	name string
	head_branch string
	event string
	status string
}

struct WorkflowList {
	total_count int
	workflow_runs []Workflow
}

fn (self Project) get_workflows() []Workflow {
	response := http.get("https://api.github.com/repos/${self.owner}/${self.project}/actions/runs") or { panic(err) }
	workflows_list := json.decode(WorkflowList, response.body) or { panic(err) }
	return workflows_list.workflow_runs
}