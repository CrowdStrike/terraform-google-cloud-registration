terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "your-csmp-infrastructure-project"
}

module "project_discovery" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/project-discovery"

  # Registration Scope - Organization Level
  registration_type = "organization"
  organization_id   = "123456789012"

  # Optional: Folder registration (alternative to organization)
  # registration_type = "folder"
  # folder_ids = ["123456789", "987654321"]

  # Optional: Project registration (alternative to organization/folder)
  # registration_type = "project"
  # project_ids = ["project-1", "project-2", "project-3"]
}
