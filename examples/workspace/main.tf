# Deploys the CrowdStrike Google Workspace root with the Terraform CLI

provider "google" {
  project = var.wif_project_id
}

module "crowdstrike_gws_registration" {
  source = "../../workspace"

  # Required: registration values from the CrowdStrike console
  gws_registration_id = var.gws_registration_id
  wif_pool_id         = var.wif_pool_id
  wif_provider_id     = var.wif_provider_id
  gws_identity_source = var.gws_identity_source
  service_account_id  = var.service_account_id

  # Required: the CrowdStrike Workspace identity (provide one based on your CS cloud)
  workspace_role_arn                  = var.workspace_role_arn
  workspace_service_account_unique_id = var.workspace_service_account_unique_id

  # Required: Google Cloud and Google Workspace
  wif_project_id  = var.wif_project_id
  organization_id = var.organization_id
  customer_id     = var.customer_id

  # Optional: set to false when an organization admin makes the grant by hand
  grant_organization_viewer = var.grant_organization_viewer

  # Optional: resource naming customization
  resource_prefix = var.resource_prefix
  resource_suffix = var.resource_suffix
}
