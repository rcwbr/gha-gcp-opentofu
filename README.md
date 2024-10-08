# gha-gcp-opentofu

State bucket and access resources for managing [OpenTofu](https://opentofu.org/) infrastructure-as-code via [GitHub Actions](https://docs.github.com/en/actions).

## Usage

Use this module as any other OpenTofu/TF module. As it tracks resources for its own backend and access configuration, initial provisioning requires manual apply via personal authentication and local state (see [Initalial provisioning](#initial-provisioning)). After that, recommended usage is via [Terragrunt](https://terragrunt.gruntwork.io/) (see [Terragrunt usage](#terragrunt-usage)).

### Terragrunt usage

Recommended usage of this module is via [Terragrunt](https://terragrunt.gruntwork.io/). Basic Terragrunt usage of the module:

```hcl
terraform {
  source = "github.com/rcwbr/gha-gcp-opentofu?ref=0.1.0"
}

inputs = {
  gcp_project = "my-project"
  gcp_region = "us-west-1"
  github_repo = "my-repo"
  state_bucket_name = "my-repo-state-bucket"
}
```

As an example, this project uses `.infra/terragrunt.hcl` to configure the bucket as the state backend, as it could be used for resources for any provider, and `.infra/gcp-gha-gcp-opentofu/terragrunt.hcl` to configure the GCP provider and the module itself.

The `.infra/terragrunt.hcl` file configures the state backend:

```hcl
// .infra/terragrunt.hcl
locals {
  state_bucket_name = "${local.github_repo}-opentofu-state"
  gcp_project = "gha-gcp-opentofu"
  gcp_region = "US-WEST1"
  github_repo = "rcwbr/gha-gcp-opentofu"
}

remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = local.state_bucket_name
    prefix = "${path_relative_to_include()}"
    project = local.gcp_project
    location = local.gcp_region
    access_token = get_env("GOOGLE_OAUTH_ACCESS_TOKEN", "")
  }
}

inputs = {
  github_repo = local.github_repo
  state_bucket_name = local.state_bucket_name
}
```

The `.infra/gcp-gha-gcp-opentofu/terragrunt.hcl` file defines the GCP provider and wraps the module:

```hcl
// .infra/gcp-gha-gcp-opentofu/terragrunt.hcl
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
```


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

### Initial provisioning

Initial provisioning of resources to enable infrastructue-as-code automation requires the following steps:

1. Prepare a GCS project
1. Temporarily grant your personal account the Storage Admin for access to the state bucket after `apply`:

    ```bash
    docker run --rm -it --entrypoint bash gcr.io/google.com/cloudsdktool/google-cloud-cli -c 'gcloud auth login && gcloud projects add-iam-policy-binding gha-gcp-opentofu-7 --member="user:eric@eweber.me" --role="roles/storage.admin"'
    ```
    1. Follow the instructions provided by the prompts to authenticate the action

1. Retrieve a GCP access token:

    ```bash
    docker run --rm -it --entrypoint bash -v gcp_application_default_token:/token_vol gcr.io/google.com/cloudsdktool/google-cloud-cli -c 'gcloud auth application-default login && gcloud auth application-default print-access-token > /token_vol/gcp_application_default_token'
    ```
    1. Similarly, follow the prompts to authenticate the environment

1. Plan and apply the provisioning resources from the infrastructure-as-code config:

    ```bash
    docker run -it --rm -v gcp_application_default_token:/token_vol -v $(pwd):/gha-gcp-opentofu -w /gha-gcp-opentofu/.infra/gcp-gha-gcp-opentofu --entrypoint bash devopsinfra/docker-terragrunt:ot-1.8.2-tg-0.67.10 -c 'export GOOGLE_OAUTH_ACCESS_TOKEN=$(cat /token_vol/gcp_application_default_token) && terragrunt plan -target="google_iam_workload_identity_pool.github_actions"  -target="google_project_service.iam" -target="google_project_service.iam_creds" -target="google_project_service.crm" -target="google_iam_workload_identity_pool_provider.github_actions" -target="google_service_account.github_actions_plan" -target="google_service_account_iam_policy.github_actions_plan" -target="google_service_account.github_actions_apply" -target="google_service_account_iam_policy.github_actions_apply" -target="google_project_iam_member.github_actions_apply_sa_admin" -target="google_storage_bucket_iam_policy.state_bucket_policy" -target="google_project_iam_custom_role.plan_project_role" -target="google_project_iam_member.github_actions_plan_sa_custom" -target="google_project_iam_member.github_actions_plan_sa_viewer" && terragrunt apply -target="google_project_service.iam" -target="google_project_service.iam_creds" -target="google_project_service.crm" -target="google_iam_workload_identity_pool.github_actions" -target="google_iam_workload_identity_pool_provider.github_actions" -target="google_service_account.github_actions_plan" -target="google_service_account_iam_policy.github_actions_plan" -target="google_service_account.github_actions_apply" -target="google_service_account_iam_policy.github_actions_apply" -target="google_project_iam_member.github_actions_apply_sa_admin" -target="google_storage_bucket_iam_policy.state_bucket_policy" -target="google_project_iam_custom_role.plan_project_role" -target="google_project_iam_member.github_actions_plan_sa_custom" -target="google_project_iam_member.github_actions_plan_sa_viewer"'
    ```
    1. This will prompt with `Remote state GCS bucket opentofu-state does not exist or you don't have permissions to access it. Would you like Terragrunt to create it? (y/n)`. Enter `y`
    1. It will then prompt with `Do you want to perform these actions? OpenTofu will perform the actions described above. Only 'yes' will be accepted to approve.`. Enter `yes`
    1. Note the value of the `github_actions_wif_provider_id`, `github_actions_apply_sa_email`, and `github_actions_plan_sa_email` outputs provided by logs from this command in the `Outputs:` block (see [GitHub Actions usage](#github-actions-usage))
    1. Clean up the volume storing the GCP auth token: `docker volume rm gcp_application_default_token`

1. Clean up the temporary personal account Storage Admin role binding:

    ```bash
    docker run --rm -it --entrypoint bash gcr.io/google.com/cloudsdktool/google-cloud-cli -c 'gcloud auth login && gcloud projects remove-iam-policy-binding gha-gcp-opentofu-7 --member="user:eric@eweber.me" --role="roles/storage.admin"'
    ```
    1. Follow the instructions provided by the prompts to authenticate the action

1. Trigger a `main` branch workflow to apply the remaining resources via GitHub Actions

