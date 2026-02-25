# Example: Folder-level log ingestion
# This example assumes you already have workload identity configured
# and shows how to use the log-ingestion module for specific folders

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

# Use the log-ingestion module for folder registration
module "log_ingestion" {
  source = "../.."

  # WIF principal from your workload-identity module output
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/crowdstrike-wif-pool/subject/arn:aws:sts::280492971771:assumed-role/crowdstrike-gcp-wif-role/folder-123"

  registration_type = "folder"
  registration_id   = "folder-123"
  folder_ids        = ["987654321098", "876543210987"] # Multiple folder IDs

  # Infrastructure project where Pub/Sub resources will be created
  infra_project_id = "my-crowdstrike-project"

  # WIF project (usually same as infra_project_id unless separated)
  wif_project_id = "my-crowdstrike-project"

  # Custom log types for folder-level monitoring
  audit_log_types = ["activity", "system_event"]

  # Folder-specific exclusions
  exclusion_filters = [
    "resource.labels.environment=\"development\"",
    "resource.labels.team=\"intern\""
  ]

  # Moderate retention settings for folder scope
  message_retention_duration = "604800s" # 7 days
  ack_deadline_seconds       = 300       # 5 minutes

  # Resource naming for folder scope
  resource_prefix = "cs-folder"

  labels = {
    environment = "production"
    owner       = "crowdstrike"
    scope       = "folder"
    managed-by  = "terraform"
  }
}
