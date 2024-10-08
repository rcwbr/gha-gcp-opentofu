# gha-gcp-opentofu

State bucket and access resources for managing [OpenTofu](https://opentofu.org/) infrastructure-as-code via [GitHub Actions](https://docs.github.com/en/actions).

## Usage


### Module inputs

The module reads the following variables as input:

| Variable | Required | Default | Effect |
| --- | --- | --- | --- |
| `gcp_project` | &check; | N/A | The GCP project name |
| `gcp_region` | &check; | N/A | The GCP region for all resources managed within the project |
| `github_repo` | &check; | N/A | The fully-qualified name of the GitHub repo to which the state access will be granted |
| `apply_action_project_roles` | &cross; | `[ "roles/iam.serviceAccountAdmin", "roles/storage.admin", "roles/iam.workloadIdentityPoolAdmin" ]` | The list of project-wide roles to grant apply actions |
| `github_default_branch_name` | &cross; | `"main"` | The default/mainline branch name for the GitHub repo, workflows for which have OpenTofu apply (vs. plan) access |
| `state_bucket_name` | &cross; | `"${var.gcp_project}-opentofu-state"` | The name of the bucket used for OpenTofu state |
