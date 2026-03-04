# Example: Project-level asset inventory
# This example assumes you already have workload identity configured
# and shows how to use the asset-inventory module for specific projects

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
  project = "my-crowdstrike-project" # Replace with your actual project ID
  region  = "us-central1"
}

# Use the asset-inventory module for project registration
module "asset-inventory" {
  source = "../.."

  # WIF principal from your workload-identity module output
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/crowdstrike-wif-pool/subject/arn:aws:sts::280492971771:assumed-role/crowdstrike-gcp-wif-role/project-123"

  registration_type = "project"

  # WIF project (usually same as infra project unless separated)
  wif_project_id = "my-crowdstrike-project"

  # Projects list used by the module
  project_ids = [
    "my-specific-project" # Replace with your project IDs
  ]

  # Optional: Customize IAM roles if needed
  google_iam_roles = [
    "roles/browser",
    "roles/cloudasset.viewer",
    "roles/compute.viewer",
    "roles/securitycenter.adminViewer"
  ]
}
