# Example: Folder-level asset inventory
# This example assumes you already have workload identity configured
# and shows how to use the asset-inventory module for folder registration

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

# Use the asset-inventory module for folder registration
module "asset-inventory" {
  source = "../.."

  # WIF principal
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/crowdstrike-wif-pool/subject/arn:aws:sts::280492971771:assumed-role/crowdstrike-gcp-wif-role/folder-123"

  registration_type = "folder"
  folder_ids        = ["111111111111"] # Replace with your folder IDs

  # WIF project (usually same as infra project unless separated)
  wif_project_id = "my-crowdstrike-project"
}
