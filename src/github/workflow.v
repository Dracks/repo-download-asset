module github

import net.http
import json

pub struct Workflow {
pub:
	id          i64
	name        string
	head_branch string
	event       string
	status      string
	conclusion  string
	run_number  int
	workflow_id i64
}

struct WorkflowList {
	total_count   int
	workflow_runs []Workflow
}

pub fn (self Project) get_workflows() []Workflow {
	response := http.get('https://api.github.com/repos/${self.owner}/${self.name}/actions/runs') or {
		panic(err)
	}
	workflows_list := json.decode(WorkflowList, response.body) or { panic(err) }
	return workflows_list.workflow_runs
}
