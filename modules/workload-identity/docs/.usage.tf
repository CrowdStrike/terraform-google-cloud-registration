terraform {
  required_version = ">= 1.2.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "my-gcp-project"
}

# Create workload identity federation resources
module "workload_identity" {
  source = "CrowdStrike/cloud-registration/gcp//modules/workload-identity"

  # Required: Project where WIF resources will be created
  wif_project_id = "my-security-project"

  # Required: Pool and provider IDs (supplied by CrowdStrike during registration)
  wif_pool_id          = "cs-fcs-wif-abcd1234efgh5678"
  wif_pool_provider_id = "cs-provider-abcd1234efgh5678"

  # Required: CrowdStrike's AWS account ID
  aws_account_id = "123456789012"

  # Required: Display names for the resources
  wif_pool_name          = "CrowdStrike-WIF-Pool"
  wif_pool_provider_name = "CrowdStrike-AWS-Provider"

  # Optional: Resource naming
  resource_prefix = "cs"
  resource_suffix = "prod"
}