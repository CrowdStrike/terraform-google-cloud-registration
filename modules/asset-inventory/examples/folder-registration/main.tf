# Example: Folder-level asset inventory
# This example assumes you already have workload identity configured
# and shows how to use the asset-inventory module for folder registration

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

# Use the asset-inventory module for folder registration
module "asset-inventory" {
  source = "../.."

  # WIF principal
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/crowdstrike-wif-pool/subject/arn:aws:sts::280492971771:assumed-role/crowdstrike-gcp-wif-role/folder-123"
  
  registration_type = "folder"
  organization_id   = ""
  folder_ids        = "111111111111"  # Replace with your folder ID
  project_ids       = ""
  
  # Discovered projects list (from project-discovery module output)
  discovered_projects = [
    "my-folder-project-1",
    "my-folder-project-2"
  ]
}