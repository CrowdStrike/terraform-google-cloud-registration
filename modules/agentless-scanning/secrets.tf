# =============================================================================
# Secret Manager - Falcon Client Credentials (per host project)
# =============================================================================

resource "google_secret_manager_secret" "falcon_credentials" {
  for_each = toset(local.host_project_ids)

  project   = each.value
  secret_id = "${var.resource_prefix}csscanning-falcon-credentials-${local.reg_id_short}${var.resource_suffix}"

  labels = var.labels

  replication {
    auto {}
  }

  depends_on = [google_project_service.required_apis]
}

resource "google_secret_manager_secret_version" "falcon_credentials" {
  for_each = toset(local.host_project_ids)

  secret = google_secret_manager_secret.falcon_credentials[each.value].id
  secret_data = jsonencode({
    clientId     = var.falcon_client_id
    clientSecret = var.falcon_client_secret
  })
}

resource "google_secret_manager_secret_iam_member" "scanner_access" {
  for_each = toset(local.host_project_ids)

  project   = each.value
  secret_id = google_secret_manager_secret.falcon_credentials[each.value].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.scanner_sa[each.value].email}"
}
