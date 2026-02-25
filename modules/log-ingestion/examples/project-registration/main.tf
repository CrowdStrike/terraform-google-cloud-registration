# Example: Project-level log ingestion
# This example assumes you already have workload identity configured
# and shows how to use the log-ingestion module for specific projects

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

# Use the log-ingestion module for project registration
module "log_ingestion" {
  source = "../.."

  # WIF principal from your workload-identity module output
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/crowdstrike-wif-pool/subject/arn:aws:sts::280492971771:assumed-role/crowdstrike-gcp-wif-role/project-123"

  registration_type = "project"
  registration_id   = "project-123"
  project_ids       = ["my-specific-project"] # Replace with your project IDs

  # Infrastructure project where Pub/Sub resources will be created
  infra_project_id = "my-crowdstrike-project"

  # WIF project (usually same as infra_project_id unless separated)
  wif_project_id = "my-crowdstrike-project"

  # Optional: Basic log retention settings
  message_retention_duration = "604800s" # 7 days
  ack_deadline_seconds       = 300       # 5 minutes

  # Optional: Resource labeling
  labels = {
    environment = "production"
    owner       = "crowdstrike"
    managed-by  = "terraform"
  }
}
