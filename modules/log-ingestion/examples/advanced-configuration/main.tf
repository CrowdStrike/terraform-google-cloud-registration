# Example: Advanced log ingestion configuration
# This example shows advanced features including schema validation,
# custom storage regions, and audit log filtering

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
  project = "my-crowdstrike-project" # Replace with your actual project ID
  region  = "us-central1"
}

# Use the log-ingestion module with advanced configuration
module "log_ingestion" {
  source = "../.."

  # WIF principal from your workload-identity module output
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789012/locations/global/workloadIdentityPools/crowdstrike-wif-pool/subject/arn:aws:sts::280492971771:assumed-role/crowdstrike-gcp-wif-role/advanced-123"

  registration_type = "organization"
  registration_id   = "advanced-123"
  organization_id   = "123456789012"

  # Infrastructure project for Pub/Sub resources
  infra_project_id = "my-crowdstrike-project"

  # Comprehensive audit log types including data access
  audit_log_types = ["activity", "system_event", "policy", "data_access"]

  # Complex exclusion filters for large organizations
  exclusion_filters = [
    "resource.labels.environment=\"test\"",
    "resource.labels.temporary=\"true\"",
    "resource.labels.cost_center=\"training\"",
    "resource.type=\"gce_instance\" AND resource.labels.instance_type=\"preemptible\"",
    "protoPayload.serviceName=\"compute.googleapis.com\" AND protoPayload.methodName=\"instances.aggregatedList\""
  ]

  # Extended retention for compliance requirements
  message_retention_duration       = "2419200s" # 28 days
  topic_message_retention_duration = "5184000s" # 60 days
  ack_deadline_seconds             = 600        # 10 minutes

  # Multi-region storage for high availability
  topic_storage_regions = ["us-central1", "us-east1", "europe-west1"]

  # Enable schema validation with AVRO
  enable_schema_validation = true
  schema_type              = "AVRO"
  schema_definition = jsonencode({
    type = "record"
    name = "AuditLog"
    fields = [
      {
        name = "timestamp"
        type = "string"
      },
      {
        name = "severity"
        type = "string"
      },
      {
        name = "logName"
        type = "string"
      }
    ]
  })

  # Resource naming and labeling
  resource_prefix = "cs-enterprise"
  resource_suffix = "v2"

  labels = {
    environment    = "production"
    owner          = "crowdstrike"
    scope          = "enterprise"
    compliance     = "required"
    retention_tier = "extended"
    managed-by     = "terraform"
  }
}