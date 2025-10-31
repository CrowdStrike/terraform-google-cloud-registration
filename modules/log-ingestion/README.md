<!-- BEGIN_TF_DOCS -->
![CrowdStrike Log Ingestion Terraform Module for GCP](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

## Introduction

This Terraform module sets up real-time log streaming from Google Cloud to CrowdStrike for Real Time Visibility and Detection (RTV&D). It creates Pub/Sub topics, subscriptions, and log router sinks to capture and forward Google Cloud Audit logs to CrowdStrike's cloud security platform for threat detection and monitoring.

## Usage

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "my-gcp-project"
}

# Configure log ingestion for RTV&D
module "log_ingestion" {
  source = "CrowdStrike/cloud-registration/gcp//modules/log-ingestion"

  # Required: Workload Identity Federation principal from workload-identity module
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789/locations/global/workloadIdentityPools/cs-wif-pool/subject/my-registration-id"

  # Required: Registration scope and identifiers
  registration_type = "project"
  registration_id   = "my-registration-id"  # From CrowdStrike Registration API

  # Required: Project for CrowdStrike infrastructure resources
  crowdstrike_infra_project_id = "my-security-project"

  # Conditional: Required based on registration_type
  organization_id = ""           # Required if registration_type = "organization"
  folder_ids      = ""           # Required if registration_type = "folder" (comma-separated)
  project_ids     = "my-project" # Required if registration_type = "project" (comma-separated)

  # Optional: Resource naming
  resource_prefix = "cs"
  resource_suffix = "prod"

  # Optional: Audit log configuration
  audit_log_types = ["activity", "system_event", "policy"] # Admin Activity, System Event, Policy Denied
  exclusion_filters = [
    "resource.labels.project_id=\"sensitive-project\"",
    "protoPayload.serviceName=\"storage.googleapis.com\""
  ]

  # Optional: Pub/Sub Topic configuration
  topic_message_retention_duration = "604800s"  # 7 days
  topic_storage_regions = ["us-central1", "us-east1"]
  
  # Optional: Schema validation
  enable_schema_validation = false
  schema_definition = ""
  schema_type = "AVRO"

  # Optional: Pub/Sub Subscription configuration
  message_retention_duration = "604800s"  # 7 days
  ack_deadline_seconds = 600              # 10 minutes

  # Optional: Use existing resources instead of creating new ones
  existing_topic_name = ""        # Use existing topic (empty = create new)
  existing_subscription_name = "" # Use existing subscription (empty = create new)

  # Optional: Resource labels
  labels = {
    environment = "prod"
    team        = "security"
  }
}
```

## Registration Scopes

This module supports three registration scopes for log collection:

### Organization-level Registration
```hcl
module "log_ingestion" {
  # ... other configuration ...
  
  registration_type = "organization"
  organization_id   = "123456789012"
}
```

### Folder-level Registration
```hcl
module "log_ingestion" {
  # ... other configuration ...
  
  registration_type = "folder"
  folder_ids        = "folder1,folder2,folder3"
}
```

### Project-level Registration
```hcl
module "log_ingestion" {
  # ... other configuration ...
  
  registration_type = "project"
  project_ids       = "project1,project2,project3"
}
```

## Advanced Configuration

### Audit Log Filtering

Configure which audit log types to collect and optionally exclude specific resources:

```hcl
module "log_ingestion" {
  # ... other configuration ...
  
  # Specify audit log types (default: Admin Activity, System Event, Policy Denied)  
  audit_log_types = ["activity", "system_event", "policy", "data_access"]
  
  # Exclude specific resources from log collection
  exclusion_filters = [
    "resource.labels.project_id=\"sensitive-project\"",
    "resource.labels.project_id=\"test-environment\"",
    "protoPayload.serviceName=\"storage.googleapis.com\""
  ]
}
```

### Using Existing Pub/Sub Resources

Instead of creating new Pub/Sub resources, you can use existing ones:

```hcl
module "log_ingestion" {
  # ... other configuration ...
  
  # Use existing topic and subscription
  existing_topic_name = "my-existing-log-topic"
  existing_subscription_name = "my-existing-log-subscription"
}
```

### Enhanced Pub/Sub Topic Configuration

Configure advanced topic settings including retention, regional storage, and schema validation:

```hcl
module "log_ingestion" {
  # ... other configuration ...
  
  # Topic message retention (default: 7 days)
  topic_message_retention_duration = "1209600s"  # 14 days
  
  # Regional message storage
  topic_storage_regions = ["us-central1", "us-east1"]
  
  # Enable schema validation
  enable_schema_validation = true
  schema_type = "AVRO"
  schema_definition = jsonencode({
    type = "record"
    name = "AuditLog"
    fields = [
      {
        name = "@type"
        type = "string"
      }
      # ... additional schema fields
    ]
  })
}
```

### Subscription Configuration

Customize subscription settings for message processing:

```hcl
module "log_ingestion" {
  # ... other configuration ...
  
  # Subscription message retention (default: 7 days)
  message_retention_duration = "1209600s"  # 14 days
  
  # Message acknowledgment deadline (default: 10 minutes)
  ack_deadline_seconds = 300  # 5 minutes
}
```

## Resources Created

This module creates the following Google Cloud resources:

### Pub/Sub Resources
- **Pub/Sub Topic**: Receives audit logs from log router sinks (optional if using existing)
- **Pub/Sub Subscription**: CrowdStrike pulls logs from this subscription for processing (optional if using existing)
- **Pub/Sub Schema**: Optional schema validation for incoming messages

### Logging Resources
- **Log Router Sink**: Routes audit logs based on registration scope
  - Organization sink (for organization-level registration)
  - Folder sinks (for folder-level registration)
  - Project sinks (for project-level registration)

### IAM Bindings
- **Log Writer Permissions**: Grants log router service accounts publisher access to topic
- **CrowdStrike Permissions**: Grants subscriber and viewer access to CrowdStrike's federated identity

## Log Types Captured

The module captures these Google Cloud Audit log types:

- **Admin Activity Logs**: Administrative operations (create, update, delete resources)
- **System Event Logs**: System-generated events (maintenance, scaling)
- **Policy Denied Logs**: Access attempts denied by security policies

## Scaling and Performance

### Exactly Once Delivery
- Enables exactly once delivery for reliable message processing
- Supports multiple concurrent subscribers for horizontal scaling

### Message Retention
- Configurable message retention (default: 7 days)
- Configurable acknowledgment deadline (default: 10 minutes)
- Automatic retry with exponential backoff

### Regional Optimization
- Optional region specification for topic storage
- Optimized for CrowdStrike's processing infrastructure

## APIs Enabled

The module automatically enables these Google Cloud APIs:

- Cloud Resource Manager API (`cloudresourcemanager.googleapis.com`)
- Identity and Access Management API (`iam.googleapis.com`)
- Cloud Logging API (`logging.googleapis.com`)
- Cloud Pub/Sub API (`pubsub.googleapis.com`)
- Cloud Monitoring API (`monitoring.googleapis.com`)
- Service Usage API (`serviceusage.googleapis.com`)

## Security Considerations

- **Least Privilege**: Only grants necessary Pub/Sub permissions to CrowdStrike
- **Audit Trail**: All log access is tracked through Cloud Audit Logs
- **Federated Identity**: Uses Workload Identity Federation, no service account keys
- **Encrypted Transit**: All log data is encrypted in transit via Pub/Sub
- **Filtered Logs**: Only audit logs matching the specified scope are forwarded

## Costs

The module creates billable Google Cloud resources:

- **Pub/Sub Topic/Subscription**: $0.40/million operations, $0.27/GB/month storage
- **Log Router Sink**: No additional cost (part of Cloud Logging)
- **Free Tier**: First 10 GiB/month is free

Costs depend on:
- Volume of audit logs generated
- Message retention duration
- Geographic region selected

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [google_logging_folder_sink.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_folder_sink) | resource |
| [google_logging_organization_sink.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_organization_sink) | resource |
| [google_logging_project_sink.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_project_sink) | resource |
| [google_project_service.log_ingestion_apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_pubsub_schema.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_schema) | resource |
| [google_pubsub_subscription.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_subscription_iam_member.crowdstrike_subscriber](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription_iam_member) | resource |
| [google_pubsub_topic.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic_iam_member.crowdstrike_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_pubsub_topic_iam_member.log_writer_folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_pubsub_topic_iam_member.log_writer_org](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_pubsub_topic_iam_member.log_writer_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [data.google_pubsub_subscription.existing_crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/pubsub_subscription) | data source |
| [data.google_pubsub_topic.existing_crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/pubsub_topic) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ack_deadline_seconds"></a> [ack\_deadline\_seconds](#input\_ack\_deadline\_seconds) | Message acknowledgment deadline in seconds | `number` | `600` | no |
| <a name="input_audit_log_types"></a> [audit\_log\_types](#input\_audit\_log\_types) | List of audit log types to include in the filter | `list(string)` | `["activity", "system_event", "policy"]` | no |
| <a name="input_crowdstrike_infra_project_id"></a> [crowdstrike\_infra\_project\_id](#input\_crowdstrike\_infra\_project\_id) | Project ID used for CrowdStrike infrastructure resources (topic, subscription, and other components). Defaults to WIF project if not specified | `string` | `""` | no |
| <a name="input_enable_schema_validation"></a> [enable\_schema\_validation](#input\_enable\_schema\_validation) | Enable schema validation for the topic | `bool` | `false` | no |
| <a name="input_exclusion_filters"></a> [exclusion\_filters](#input\_exclusion\_filters) | List of exclusion filter expressions to exclude specific resources from log collection (e.g., 'resource.labels.project_id="excluded-project"') | `list(string)` | `[]` | no |
| <a name="input_existing_subscription_name"></a> [existing\_subscription\_name](#input\_existing\_subscription\_name) | Name of existing Pub/Sub subscription to use. If empty, creates new subscription | `string` | `""` | no |
| <a name="input_existing_topic_name"></a> [existing\_topic\_name](#input\_existing\_topic\_name) | Name of existing Pub/Sub topic to use. If empty, creates new topic | `string` | `""` | no |
| <a name="input_folder_ids"></a> [folder\_ids](#input\_folder\_ids) | Comma separated list of the Google Cloud folders being registered | `string` | `""` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Map of labels to be applied to all resources created by this module | `map(string)` | `{}` | no |
| <a name="input_message_retention_duration"></a> [message\_retention\_duration](#input\_message\_retention\_duration) | Message retention duration for Pub/Sub subscription (e.g., '604800s' for 7 days) | `string` | `"604800s"` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | The Google Cloud organization being registered | `string` | `""` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | Comma separated list of the Google Cloud projects being registered | `string` | `""` | no |
| <a name="input_registration_id"></a> [registration\_id](#input\_registration\_id) | Unique registration ID returned by CrowdStrike Registration API | `string` | n/a | yes |
| <a name="input_registration_type"></a> [registration\_type](#input\_registration\_type) | The scope of the Google Cloud registration which can be one of the following values: organization, folder, project | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix to be added to all created resource names for identification | `string` | `""` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Suffix to be added to all created resource names for identification | `string` | `""` | no |
| <a name="input_schema_definition"></a> [schema\_definition](#input\_schema\_definition) | Avro or Protocol Buffer schema definition (required if enable_schema_validation is true) | `string` | `""` | no |
| <a name="input_schema_type"></a> [schema\_type](#input\_schema\_type) | Schema type: 'AVRO' or 'PROTOCOL_BUFFER' | `string` | `"AVRO"` | no |
| <a name="input_topic_message_retention_duration"></a> [topic\_message\_retention\_duration](#input\_topic\_message\_retention\_duration) | Message retention duration for Pub/Sub topic (e.g., '604800s' for 7 days) | `string` | `"604800s"` | no |
| <a name="input_topic_storage_regions"></a> [topic\_storage\_regions](#input\_topic\_storage\_regions) | Regions for topic message storage. If empty, uses default region | `list(string)` | `[]` | no |
| <a name="input_wif_iam_principal"></a> [wif\_iam\_principal](#input\_wif\_iam\_principal) | Google Cloud IAM Principal that identifies CrowdStrike resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apis_enabled"></a> [apis\_enabled](#output\_apis\_enabled) | List of Google Cloud APIs enabled for log ingestion |
| <a name="output_log_filter"></a> [log\_filter](#output\_log\_filter) | The log filter used by the log router sinks |
| <a name="output_log_ingestion_project_id"></a> [log\_ingestion\_project\_id](#output\_log\_ingestion\_project\_id) | Project ID where log ingestion resources are deployed |
| <a name="output_log_sink_names"></a> [log\_sink\_names](#output\_log\_sink\_names) | Names of the created log router sinks |
| <a name="output_log_sink_writer_identities"></a> [log\_sink\_writer\_identities](#output\_log\_sink\_writer\_identities) | Writer identities for the created log router sinks |
| <a name="output_pubsub_topic_id"></a> [pubsub\_topic\_id](#output\_pubsub\_topic\_id) | The generated ID of the Google Cloud pub/sub topic |
| <a name="output_pubsub_topic_name"></a> [pubsub\_topic\_name](#output\_pubsub\_topic\_name) | The name of the Google Cloud pub/sub topic |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | The subscription that will be used to ingest data from the Google Cloud Pub/Sub topic |
| <a name="output_subscription_name"></a> [subscription\_name](#output\_subscription\_name) | The name of the Google Cloud pub/sub subscription |

<!-- END_TF_DOCS -->