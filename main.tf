terraform {
  required_providers {
    google = "~> 6.5.0"
  }
}

// Enable APIs
resource "google_project_service" "iam" {
  service = "iam.googleapis.com"
}
resource "google_project_service" "iam_creds" {
  service = "iamcredentials.googleapis.com"
}
resource "google_project_service" "crm" {
  service = "cloudresourcemanager.googleapis.com"
}

// WIF access and identity resources
resource "google_iam_workload_identity_pool" "github_actions" {
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions plan pool"
}
resource "google_iam_workload_identity_pool_provider" "github_actions" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "GitHub Actions plan provider"

  // GitHub Actions-GCP OIDC basic config (see https://github.com/terraform-google-modules/terraform-google-github-actions-runners/tree/master/modules/gh-oidc)
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  // Condition (https://cloud.google.com/iam/docs/reference/rest/v1/projects.locations.workloadIdentityPools.providers#WorkloadIdentityPoolProvider.FIELDS.attribute_condition)
  // to grant access to workflows only from the target GitHub repository (https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
  attribute_condition = "assertion.repository == \"${var.github_repo}\""
}

// Authorization resources for plan actions (any workflow)
resource "google_service_account" "github_actions_plan" {
  account_id   = "github-actions-plan"
  display_name = "GitHub Actions OpenTofu plan access account"
}
resource "google_service_account_iam_policy" "github_actions_plan" {
  service_account_id = google_service_account.github_actions_plan.name
  policy_data        = data.google_iam_policy.github_actions_plan_sa_bindings.policy_data
}
resource "google_project_iam_custom_role" "plan_project_role" {
  role_id     = "planProjectRole"
  title       = "Plan project role"
  description = "Role for project-level permissions for plan actions"
  permissions = [
    "storage.buckets.get",
    "storage.buckets.getIamPolicy"
  ]
}
resource "google_project_iam_member" "github_actions_plan_sa_custom" {
  project = var.gcp_project
  role    = google_project_iam_custom_role.plan_project_role.name
  member  = google_service_account.github_actions_plan.member
}
resource "google_project_iam_member" "github_actions_plan_sa_viewer" {
  project = var.gcp_project
  role    = "roles/viewer"
  member  = google_service_account.github_actions_plan.member
}


// Authorization resources for apply actions (default branch workflows only)
resource "google_service_account" "github_actions_apply" {
  account_id   = "github-actions-apply"
  display_name = "GitHub Actions OpenTofu apply access account"
}
resource "google_service_account_iam_policy" "github_actions_apply" {
  service_account_id = google_service_account.github_actions_apply.name
  policy_data        = data.google_iam_policy.github_actions_apply_sa_bindings.policy_data
}
// Grant apply service account roles to administer project resources
resource "google_project_iam_member" "github_actions_apply_sa_admin" {
  for_each = toset(var.apply_action_project_roles)
  project  = var.gcp_project
  role     = each.key
  member   = google_service_account.github_actions_apply.member
}

// OpenTofu state bucket access
resource "google_storage_bucket_iam_policy" "state_bucket_policy" {
  bucket      = data.google_storage_bucket.state_bucket.name
  policy_data = data.google_iam_policy.state_bucket.policy_data
}
