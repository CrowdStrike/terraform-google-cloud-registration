data "google_project" "wif_project" {
  project_id = var.wif_project_id
}

locals {
  aws_account_id = var.identity_source == "aws-sts" ? split(":", var.role_arn)[4] : null
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
  description               = "CrowdStrike Workload Identity Pool"
  project                   = var.wif_project_id

  depends_on = [
    google_project_service.required_apis
  ]
}

# AWS provider — created when identity_source is aws-sts
resource "google_iam_workload_identity_pool_provider" "aws" {
  count = var.identity_source == "aws-sts" ? 1 : 0

  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_pool_provider_id
  display_name                       = "${var.resource_prefix}CrowdStrikeProvider${var.resource_suffix}"
  description                        = "CrowdStrike AWS identity provider for federation"
  project                            = var.wif_project_id

  aws {
    account_id = local.aws_account_id
  }

  attribute_mapping = {
    "google.subject" = "assertion.arn"
  }

  depends_on = [google_iam_workload_identity_pool.main]
}

# OIDC provider — created when identity_source is gcp-oidc
resource "google_iam_workload_identity_pool_provider" "oidc" {
  count = var.identity_source == "gcp-oidc" ? 1 : 0

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
    "google.subject" = "assertion.sub + '/' + assertion.aud"
  }

  attribute_condition = "assertion.sub in [${join(", ", [for id in compact([var.service_account_unique_id, var.agentless_scanning_service_account_unique_id]) : "'${id}'"])}]"

  depends_on = [google_iam_workload_identity_pool.main]
}
