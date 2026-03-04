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

module "workload_identity" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/workload-identity"

  # GCP Project Configuration
  wif_project_id = "your-csmp-infrastructure-project"

  # Workload Identity Pool Configuration
  wif_pool_id          = "cs-wif-pool-12345"
  wif_pool_provider_id = "cs-provider-12345"

  # CrowdStrike Role ARN
  role_arn = "arn:aws:sts::111111111111:assumed-role/CrowdStrikeConnectorRoleName"

  # Registration ID
  registration_id = "unique-registration-id"

  # Optional: Resource Naming
  resource_prefix = "cs-"
  resource_suffix = "-prod"
}
