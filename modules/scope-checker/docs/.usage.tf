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
  project = "your-cspm-infrastructure-project"
}

module "scope_checker" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/scope-checker"

  # Registration configuration
  registration_type = "folder"
  folder_ids        = ["904504220746"]
  infra_project_id  = "my-infra-project"
}

# Use the output to conditionally create resources
output "project_in_scope" {
  description = "Whether the infrastructure project is within registration scope"
  value       = module.scope_checker.infra_project_in_scope
}
