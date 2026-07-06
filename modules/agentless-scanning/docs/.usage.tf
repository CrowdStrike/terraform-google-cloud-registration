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
  project = "your-infrastructure-project"
}

module "agentless_scanning" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/agentless-scanning"

  # Registration context
  registration_type = "project"
  registration_id   = "unique-registration-id"

  # Project scope
  host_project_id  = "your-infrastructure-project"
  project_ids      = ["your-infrastructure-project"]

  # Workload Identity Federation
  wif_project_number        = "123456789"
  wif_pool_id               = "cs-wif-pool-12345"
  agentless_scanning_role_arn = "arn:aws:sts::111111111111:assumed-role/CrowdStrikeScannerRole"

  # Falcon credentials
  falcon_client_id     = "<Falcon API client ID>"
  falcon_client_secret = "<Falcon API client secret>"

  # Scanning regions
  regions = ["us-east1"]

  # Optional: Resource naming
  resource_prefix = "cs-"
  resource_suffix = "-prod"
}
