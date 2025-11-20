# Example: Using existing Pub/Sub resources
# This example shows how to use the log-ingestion module with pre-existing
# Pub/Sub topic and subscription resources

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

# Use the log-ingestion module with existing Pub/Sub resources
module "log_ingestion" {
  source = "../.."

  # WIF principal from your workload-identity module output
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/crowdstrike-wif-pool/subject/arn:aws:sts::280492971771:assumed-role/crowdstrike-gcp-wif-role/existing-123"
  
  registration_type = "project"
  registration_id   = "existing-123"
  project_ids       = ["my-specific-project"]
  
  # Infrastructure project where existing resources are located
  infra_project_id = "my-crowdstrike-project"

  # Use existing Pub/Sub resources instead of creating new ones
  existing_topic_name        = "my-existing-audit-topic"
  existing_subscription_name = "my-existing-audit-subscription"

  # Log filtering settings (still applies even with existing resources)
  audit_log_types = ["activity", "policy"]
  
  exclusion_filters = [
    "resource.labels.skip_logging=\"true\""
  ]

  # Note: retention and ack settings don't apply to existing resources
  # Configure these directly on your existing Pub/Sub resources if needed

  labels = {
    environment = "production"
    owner       = "crowdstrike"
    type        = "existing-resources"
    managed-by  = "terraform"
  }
}