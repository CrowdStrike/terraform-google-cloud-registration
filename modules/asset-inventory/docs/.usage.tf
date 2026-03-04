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
  project = "your-csmp-infrastructure-project"
}

module "asset_inventory" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/asset-inventory"

  # CrowdStrike IAM Principal (from workload-identity module output)
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789/locations/global/workloadIdentityPools/cs-wif-pool-12345/subject/arn:aws:sts::111111111111:assumed-role/CrowdStrikeConnectorRoleName/unique-registration-id"

  # Registration Scope - Organization Level
  registration_type = "organization"
  organization_id   = "123456789012"

  # Projects discovered by project-discovery module
  discovered_projects = [
    "project-1",
    "project-2",
    "project-3"
  ]

  # Optional: Folder registration (alternative to organization)
  # registration_type = "folder"
  # folder_ids = ["123456789", "987654321"]

  # Optional: Project registration (alternative to organization/folder)
  # registration_type = "project"
  # project_ids = ["project-1", "project-2"]
}
