# Deploys the CrowdStrike Google Workspace root with the Terraform CLI

provider "google" {
  project = var.wif_project_id
}

provider "crowdstrike" {
  client_id     = var.falcon_client_id
  client_secret = var.falcon_client_secret
  cloud         = var.falcon_cloud
}

module "crowdstrike_gws_registration" {
  source = "../../workspace"

  # Required: the Google Cloud registration that has the Workspace, from the CrowdStrike console
  gcp_registration_id = var.gcp_registration_id

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
