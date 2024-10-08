locals {
  state_bucket_name = "rcwbr-gha-gcp-opentofu-7-opentofu-state"
  gcp_project       = "gha-gcp-opentofu-7"
  gcp_region        = "US-WEST1"
  github_repo       = "rcwbr/gha-gcp-opentofu"
}

remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = local.state_bucket_name
    prefix       = "${path_relative_to_include()}"
    project      = local.gcp_project
    location     = local.gcp_region
    access_token = get_env("GOOGLE_OAUTH_ACCESS_TOKEN", "")
  }
}

inputs = {
  github_repo       = local.github_repo
  state_bucket_name = local.state_bucket_name
}
