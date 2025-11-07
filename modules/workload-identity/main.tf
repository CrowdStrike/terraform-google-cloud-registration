# Data source to get project information
data "google_project" "wif_project" {
  project_id = var.wif_project_id
}

# Enable Service Usage API first (if not already enabled)
resource "google_project_service" "serviceusage" {
  project = var.wif_project_id
  service = "serviceusage.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Then enable other required services
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

# Create Workload Identity Pool
resource "google_iam_workload_identity_pool" "main" {
  workload_identity_pool_id = var.wif_pool_id
  display_name              = "${var.resource_prefix}CrowdStrikeIDPool${var.resource_suffix}"
  description               = "CrowdStrike Workload Identity Pool for AWS federation"
  project                   = var.wif_project_id

  # Ensure required APIs are enabled before creating the pool
  depends_on = [
    google_project_service.required_apis
  ]
}

# Create AWS Provider in the pool
resource "google_iam_workload_identity_pool_provider" "aws" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.main.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_pool_provider_id
  display_name                       = "${var.resource_prefix}CrowdStrikeProvider${var.resource_suffix}"
  description                        = "CrowdStrike AWS identity provider for federation"
  project                            = var.wif_project_id

  aws {
    account_id = var.aws_account_id
  }

  attribute_mapping = {
    "google.subject" = "assertion.arn"
  }

  depends_on = [
    google_iam_workload_identity_pool.main
  ]
}

