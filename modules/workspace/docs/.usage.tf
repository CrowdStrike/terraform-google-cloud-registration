terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = "your-wif-project"
}

module "workspace" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/workspace"

  # Project that holds the Workspace WIF pool
  wif_project_id = "your-wif-project"

  # Account ID of the Workspace service account, as given by CrowdStrike
  service_account_id = "csgws-0123456789a"

  # CrowdStrike Workspace principal (from workload-identity module output)
  workspace_wif_principal = "principal://iam.googleapis.com/projects/123456789/locations/global/workloadIdentityPools/cs-wif-pool-12345/subject/arn:aws:sts::111111111111:assumed-role/CrowdStrikeWorkspaceReader/unique-registration-id"

  # Organization linked to the Workspace, with no organizations/ prefix
  organization_id = "123456789012"

  # Optional: set to false when an organization admin makes the grant by hand
  grant_organization_viewer = true
}
