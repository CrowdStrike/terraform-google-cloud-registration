resource "google_project_service" "workspace_apis" {
  for_each = toset([
    "admin.googleapis.com",
    "cloudidentity.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ])

  project = var.wif_project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_service_account" "workspace_reader" {
  project      = var.wif_project_id
  account_id   = var.service_account_id
  display_name = "CrowdStrike Workspace Reader SA"
  description  = "Impersonated through WIF to read the Google Workspace directory"

  depends_on = [google_project_service.workspace_apis]
}

# Not serviceAccountTokenCreator: it also gives signJwt, signBlob and implicitDelegation.
resource "google_service_account_iam_member" "wif_can_impersonate" {
  service_account_id = google_service_account.workspace_reader.id
  role               = "roles/iam.workloadIdentityUser"
  member             = var.workspace_wif_principal
}

resource "google_organization_iam_member" "workspace_org_viewer" {
  count  = var.grant_organization_viewer ? 1 : 0
  org_id = var.organization_id
  role   = "roles/resourcemanager.organizationViewer"
  member = "serviceAccount:${google_service_account.workspace_reader.email}"
}
