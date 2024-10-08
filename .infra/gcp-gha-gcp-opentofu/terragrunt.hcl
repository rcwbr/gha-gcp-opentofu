include {
  path = find_in_parent_folders()
}

locals {
  gcp_project = read_terragrunt_config(find_in_parent_folders("terragrunt.hcl")).locals.gcp_project
  gcp_region  = lower(read_terragrunt_config(find_in_parent_folders("terragrunt.hcl")).locals.gcp_region)
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "google" {
  project       = "${local.gcp_project}"
  region        = "${local.gcp_region}"
  // Token comes from GOOGLE_OAUTH_ACCESS_TOKEN env var
}
EOF
}

terraform {
  source = "../../" // Path to the repository root
}

inputs = {
  gcp_project = local.gcp_project
  gcp_region  = local.gcp_region
}
