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
  project = "your-csmp-infrastructure-project"
}

module "crowdstrike_gcp_registration" {
  source = "CrowdStrike/terraform-google-cloud-registration"

  # CrowdStrike API Configuration
  falcon_client_id     = "<Falcon API client ID>"
  falcon_client_secret = "<Falcon API client secret>"

  # GCP Infrastructure Project
  infra_project_id = "your-csmp-infrastructure-project"

  # Registration Scope - Organization Level
  registration_type = "organization"
  organization_id   = "123456789012"

  # CrowdStrike Role ARN
  role_arn = "arn:aws:sts::111111111111:assumed-role/CrowdStrikeConnectorRoleName"

  # Optional: Enable Real Time Visibility & Detection
  enable_realtime_visibility = true

  # Optional: Log Ingestion Configuration
  log_ingestion_settings = {
    message_retention_duration       = "1209600s"  # 14 days
    ack_deadline_seconds             = 300         # 5 minutes
    topic_message_retention_duration = "2592000s"  # 30 days
    audit_log_types                  = ["activity", "system_event", "policy"]
    exclusion_filters = [
      "resource.labels.environment=\"test\"",
      "resource.labels.temporary=\"true\""
    ]
  }

  # Optional: Resource Naming
  resource_prefix = "cs-"
  resource_suffix = "-prod"

  # Optional: Resource Labels
  labels = {
    environment = "production"
    project     = "crowdstrike-integration"
    cstagvendor = "crowdstrike"
  }
}
