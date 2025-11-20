# Example: Organization-level log ingestion
# This example assumes you already have workload identity configured
# and shows how to use the log-ingestion module for organization-wide registration

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "my-crowdstrike-project" # Replace with your actual project ID
  region  = "us-central1"
}

# Use the log-ingestion module for organization registration
module "log_ingestion" {
  source = "../.."

  # WIF principal from your workload-identity module output
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/crowdstrike-wif-pool/subject/arn:aws:sts::280492971771:assumed-role/crowdstrike-gcp-wif-role/org-123"

  registration_type = "organization"
  registration_id   = "org-123"
  organization_id   = "123456789012" # Replace with your 12-digit org ID

  # Infrastructure project where Pub/Sub resources will be created
  infra_project_id = "my-crowdstrike-project"

  # Log ingestion settings
  audit_log_types = ["activity", "system_event", "policy"]

  # Exclude test and temporary resources from log collection
  exclusion_filters = [
    "resource.labels.environment=\"test\"",
    "resource.labels.temporary=\"true\"",
    "resource.labels.skip_audit=\"true\""
  ]

  # Extended retention for organization-level logs
  message_retention_duration       = "1209600s" # 14 days
  topic_message_retention_duration = "2592000s" # 30 days
  ack_deadline_seconds             = 600        # 10 minutes

  # Resource management
  resource_prefix = "cs"
  resource_suffix = "prod"

  labels = {
    environment = "production"
    owner       = "crowdstrike"
    scope       = "organization"
    managed-by  = "terraform"
  }
}