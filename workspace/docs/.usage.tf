terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.22"
    }
    crowdstrike = {
      source  = "crowdstrike/crowdstrike"
      version = ">= 1.3.0"
    }
  }
}

provider "google" {
  project = "your-wif-project"
}

# Set FALCON_CLIENT_ID, FALCON_CLIENT_SECRET and FALCON_CLOUD in the environment
provider "crowdstrike" {}

module "crowdstrike_gws_registration" {
  source = "CrowdStrike/terraform-google-cloud-registration//workspace"

  # The Google Cloud registration that has the Workspace, as given by the CrowdStrike console
  gcp_registration_id = "0123abcd-4567-89ef-0123-456789abcdef"

  # Workspace identity: workspace_role_arn (aws-sts) or workspace_service_account_unique_id (gcp-oidc)
  workspace_role_arn = "arn:aws:sts::111111111111:assumed-role/CrowdStrikeWorkspaceReader"

  # The WIF project of the Google Cloud registration
  wif_project_id = "your-wif-project"

  # The organization and the Workspace that it belongs to
  organization_id = "123456789012"
  customer_id     = "C01abc23x"
}
