locals {
  // Identity (for plan permissions) for GitHub Actions from any branch of the repo
  github_actions_plan_identity = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/*"
  // Identity (for apply permissions) for GitHub Actions from only the default branch (https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
  github_actions_apply_identity = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.ref/${var.github_default_branch_name}"

  state_bucket_name = var.state_bucket_name != "" ? var.state_bucket_name : "${var.gcp_project}-opentofu-state"
}
