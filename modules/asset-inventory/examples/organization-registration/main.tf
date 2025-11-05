# Example: Organization-level asset inventory
# This example assumes you already have workload identity configured
# and shows how to use the asset-inventory module for organization-wide registration

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "my-crowdstrike-project"  # Replace with your actual project ID
  region  = "us-central1"
}

# Use the asset-inventory module for organization registration
module "asset-inventory" {
  source = "../.."

  # WIF principal from your workload-identity module output
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/crowdstrike-wif-pool/subject/arn:aws:sts::280492971771:assumed-role/crowdstrike-gcp-wif-role/org-123"
  
  registration_type = "organization"
  organization_id   = "123456789012"  # Replace with your 12-digit org ID
  folder_ids        = ""
  project_ids       = ""
  
  # Discovered projects list (from project-discovery module output)
  discovered_projects = [
    "my-prod-project",
    "my-staging-project",
    "my-dev-project"
  ]
}