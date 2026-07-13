data "google_project" "wif_project" {
  project_id = var.wif_project_id
}

resource "google_project_service" "serviceusage" {
  project = var.wif_project_id
  service = "serviceusage.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "required_apis" {
  for_each = toset([
    "iamcredentials.googleapis.com",
    "iam.googleapis.com",
    "sts.googleapis.com"
  ])

  project = var.wif_project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false

  depends_on = [google_project_service.serviceusage]
}

resource "google_iam_workload_identity_pool" "main" {
  workload_identity_pool_id = var.wif_pool_id
  display_name              = "${var.resource_prefix}CrowdStrikeIDPool${var.resource_suffix}"
  description               = "CrowdStrike Workload Identity Pool for GCP OIDC federation"
  project                   = var.wif_project_id

  depends_on = [
    google_project_service.required_apis
  ]
}

resource "google_iam_workload_identity_pool_provider" "oidc" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_pool_provider_id
  display_name                       = "${var.resource_prefix}CrowdStrikeProvider${var.resource_suffix}"
  description                        = "CrowdStrike GCP OIDC identity provider for federation"
  project                            = var.wif_project_id

  oidc {
    issuer_uri        = "https://accounts.google.com"
    allowed_audiences = [var.registration_id]
  }

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }

  attribute_condition = "assertion.sub == '${var.service_account_unique_id}'"

  depends_on = [google_iam_workload_identity_pool.main]
}
