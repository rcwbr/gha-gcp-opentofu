variable "apply_action_project_roles" {
  type = list(string)
  default = [
    "roles/iam.serviceAccountAdmin",
    "roles/storage.admin",
    "roles/iam.workloadIdentityPoolAdmin"
  ]
  description = "The list of project-wide roles to grant apply actions"
}

variable "gcp_project" {
  type        = string
  description = "The GCP project name"
}

variable "gcp_region" {
  type        = string
  description = "The GCP region for all resources managed within the project"
}

variable "github_default_branch_name" {
  type        = string
  default     = "main"
  description = "The default/mainline branch name for the GitHub repo, workflows for which have OpenTofu apply (vs. plan) access"
}

variable "github_repo" {
  type        = string
  description = "The fully-qualified name of the GitHub repo to which the state access will be granted"
}

variable "state_bucket_name" {
  type        = string
  default     = ""
  description = "The name of the bucket to manage and use for OpenTofu state"
}
