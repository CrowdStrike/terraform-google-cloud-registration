terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "your-csmp-infrastructure-project"
}

module "log_ingestion" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/log-ingestion"

  # CrowdStrike IAM Principal (from workload-identity module output)
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789/locations/global/workloadIdentityPools/cs-wif-pool-12345/subject/arn:aws:sts::111111111111:assumed-role/CrowdStrikeConnectorRoleName/unique-registration-id"

  # CrowdStrike Infrastructure Project
  infra_project_id = "your-csmp-infrastructure-project"

  # Registration Configuration
  registration_type = "organization"
  registration_id   = "unique-registration-id"
  organization_id   = "123456789012"

  # Optional: Folder registration (alternative to organization)
  # registration_type = "folder"
  # folder_ids = ["123456789", "987654321"]

  # Optional: Project registration (alternative to organization/folder)
  # registration_type = "project"
  # project_ids = ["project-1", "project-2"]

  # Optional: Log Ingestion Settings
  audit_log_types                  = ["activity", "system_event", "policy"]
  message_retention_duration       = "1209600s"  # 14 days
  ack_deadline_seconds             = 300         # 5 minutes
  topic_message_retention_duration = "2592000s"  # 30 days

  # Optional: Exclusion Filters
  exclusion_filters = [
    "resource.labels.environment=\"test\"",
    "resource.labels.temporary=\"true\""
  ]

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
