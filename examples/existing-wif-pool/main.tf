# =============================================================================
# CrowdStrike GCP CSPM Bring-Your-Own WIF Example
# =============================================================================
# This example demonstrates project-level registration that attaches to a
# Workload Identity Federation pool owned by another registration under the
# same CID, instead of having this module create a new one. Only
# asset-inventory IAM role assignments are granted; log ingestion and
# agentless scanning are not supported in this mode.
# =============================================================================

provider "google" {
  project = var.infra_project_id
}

provider "crowdstrike" {
  client_id     = var.falcon_client_id
  client_secret = var.falcon_client_secret
}

module "crowdstrike_gcp_registration" {
  source = "../../"

  registration_name = var.registration_name
  registration_type = "project"
  deployment_method = var.deployment_method

  infra_project_id = var.infra_project_id

  project_ids = var.project_ids

  role_arn = var.role_arn

  falcon_client_id     = var.falcon_client_id
  falcon_client_secret = var.falcon_client_secret

  # Attach to the owner registration's existing WIF pool instead of creating a new one
  existing_wif_pool_id = var.existing_wif_pool_id

  resource_prefix = var.resource_prefix
  resource_suffix = var.resource_suffix

  labels = var.labels
}
