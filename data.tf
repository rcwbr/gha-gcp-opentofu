data "google_storage_bucket" "state_bucket" {
  name = local.state_bucket_name
}

data "google_iam_policy" "github_actions_plan_sa_bindings" {
  // Allow the plan identity to act as the service account
  binding {
    role    = "roles/iam.workloadIdentityUser"
    members = [local.github_actions_plan_identity]
  }

  // Allow the apply account to administer the service account
  binding {
    role    = "roles/iam.serviceAccountAdmin"
    members = [google_service_account.github_actions_apply.member]
  }
}

data "google_iam_policy" "github_actions_apply_sa_bindings" {
  // Allow the apply identity to act as the service account
  binding {
    role    = "roles/iam.workloadIdentityUser"
    members = [local.github_actions_apply_identity]
  }
  binding {
    role    = "roles/iam.serviceAccountTokenCreator"
    members = [local.github_actions_apply_identity]
  }
}

data "google_iam_policy" "state_bucket" {
  // Plan action service account state bucket binding
  binding {
    role = "roles/storage.objectUser"
    members = [
      google_service_account.github_actions_plan.member,
      google_service_account.github_actions_apply.member
    ]
  }
}
