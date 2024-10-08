output "github_actions_wif_provider_id" {
  value = google_iam_workload_identity_pool_provider.github_actions.name
}
output "github_actions_plan_sa_email" {
  value = google_service_account.github_actions_plan.email
}
output "github_actions_apply_sa_email" {
  value = google_service_account.github_actions_apply.email
}
