terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.22"
    }
  }
}

provider "google" {
  project = "your-wif-project"
}

module "crowdstrike_gws_registration" {
  source = "CrowdStrike/terraform-google-cloud-registration//workspace"

  # Registration values, as given by the CrowdStrike console
  gws_registration_id = "0123abcd-4567-89ef-0123-456789abcdef"
  wif_pool_id         = "cs-fcs-wif-0123456789abcdef"
  wif_provider_id     = "cs-provider-0123456789abcdef"
  gws_identity_source = "aws-sts"
  service_account_id  = "csgws-0123abcd456"

  # Workspace identity: workspace_role_arn (aws-sts) or workspace_service_account_unique_id (gcp-oidc)
  workspace_role_arn = "arn:aws:sts::111111111111:assumed-role/CrowdStrikeWorkspaceReader"

  # The WIF project of the Google Cloud registration
  wif_project_id = "your-wif-project"

  # The organization and the Workspace that it belongs to
  organization_id = "123456789012"
  customer_id     = "C01abc23x"
}
