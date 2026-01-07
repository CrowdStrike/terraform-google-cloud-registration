# =============================================================================
# CrowdStrike GCP CSPM Infrastructure Manager Example
# =============================================================================
# This example demonstrates how to deploy the CrowdStrike GCP CSPM Terraform
# module using GCP Infrastructure Manager.
# =============================================================================

# =============================================================================
# Data Sources for Secret Management
# =============================================================================

# Retrieve the Falcon client secret from Secret Manager if not provided directly
data "google_secret_manager_secret_version" "falcon_client_secret" {
  count   = var.falcon_client_secret == null ? 1 : 0
  secret  = var.falcon_client_secret_name
  project = var.infra_project_id
}

# =============================================================================
# Locals for configuration
# =============================================================================

locals {
  effective_wif_project_id = var.wif_project_id != null ? var.wif_project_id : var.infra_project_id
  falcon_client_secret     = var.falcon_client_secret != null ? var.falcon_client_secret : data.google_secret_manager_secret_version.falcon_client_secret[0].secret_data
}

# =============================================================================
# Provider Configuration
# =============================================================================

provider "google" {
  project = var.infra_project_id
}

provider "google" {
  alias   = "wif"
  project = local.effective_wif_project_id
}

provider "crowdstrike" {
  client_id     = var.falcon_client_id
  client_secret = local.falcon_client_secret
}

# =============================================================================
# CrowdStrike GCP Registration
# =============================================================================

module "crowdstrike_gcp_registration" {
  source = "../../"

  # Required: Registration configuration
  registration_name             = var.registration_name
  registration_type             = var.registration_type
  deployment_method             = var.deployment_method
  infrastructure_manager_region = var.infrastructure_manager_region

  # Required: GCP project configuration
  infra_project_id = var.infra_project_id
  wif_project_id   = var.wif_project_id

  # Required: Resource scope (choose one based on registration_type)
  organization_id = var.organization_id
  folder_ids      = var.folder_ids
  project_ids     = var.project_ids

  # Required: AWS integration
  role_arn = var.role_arn

  # Optional: Real-time visibility and detection
  enable_realtime_visibility = var.enable_realtime_visibility

  # Optional: Resource naming customization
  resource_prefix = var.resource_prefix
  resource_suffix = var.resource_suffix

  # Optional: Labels for resource organization
  labels = var.labels

  # Optional: Log ingestion settings
  log_ingestion_settings = var.log_ingestion_settings

  # Optional: Project exclusion patterns
  excluded_project_patterns = var.excluded_project_patterns

  providers = {
    google.wif = google.wif
  }
}
