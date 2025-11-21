<!-- BEGIN_TF_DOCS -->
![CrowdStrike Log Ingestion Terraform Module for GCP](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

## Introduction

This Terraform module sets log ingestion from Google Cloud to CrowdStrike for Real Time Visibility and Detection (RTV&D) feature. It creates Pub/Sub topics, subscriptions, and log router sinks to capture and forward Google Cloud Audit logs to CrowdStrike's cloud security platform for threat detection and monitoring.

## Usage

```hcl
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
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789/locations/global/workloadIdentityPools/cs-wif-pool-12345/subject/arn:aws:sts::532730071073:assumed-role/CrowdStrikeCSPMConnector/unique-registration-id"
  
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
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 5.45.0 |
## Resources

| Name | Type |
|------|------|
| [google_logging_folder_sink.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/logging_folder_sink) | resource |
| [google_logging_organization_sink.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/logging_organization_sink) | resource |
| [google_logging_project_sink.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/logging_project_sink) | resource |
| [google_project_iam_member.crowdstrike_monitoring_viewer](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/project_iam_member) | resource |
| [google_project_service.log_ingestion_apis](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/project_service) | resource |
| [google_pubsub_schema.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/pubsub_schema) | resource |
| [google_pubsub_subscription.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_subscription_iam_member.crowdstrike_subscriber](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/pubsub_subscription_iam_member) | resource |
| [google_pubsub_topic.crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic_iam_member.crowdstrike_viewer](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/pubsub_topic_iam_member) | resource |
| [google_pubsub_topic_iam_member.log_writer_folder](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/pubsub_topic_iam_member) | resource |
| [google_pubsub_topic_iam_member.log_writer_org](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/pubsub_topic_iam_member) | resource |
| [google_pubsub_topic_iam_member.log_writer_project](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/resources/pubsub_topic_iam_member) | resource |
| [google_pubsub_subscription.existing_crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/data-sources/pubsub_subscription) | data source |
| [google_pubsub_topic.existing_crowdstrike_logs](https://registry.terraform.io/providers/hashicorp/google/5.45.0/docs/data-sources/pubsub_topic) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ack_deadline_seconds"></a> [ack\_deadline\_seconds](#input\_ack\_deadline\_seconds) | Message acknowledgment deadline in seconds | `number` | `600` | no |
| <a name="input_audit_log_types"></a> [audit\_log\_types](#input\_audit\_log\_types) | List of audit log types to include in the filter | `list(string)` | <pre>[<br/>  "activity",<br/>  "system_event",<br/>  "policy"<br/>]</pre> | no |
| <a name="input_enable_schema_validation"></a> [enable\_schema\_validation](#input\_enable\_schema\_validation) | Enable schema validation for the topic | `bool` | `false` | no |
| <a name="input_exclusion_filters"></a> [exclusion\_filters](#input\_exclusion\_filters) | List of exclusion filter expressions to exclude specific resources from log collection (e.g., 'resource.labels.project\_id="excluded-project"') | `list(string)` | `[]` | no |
| <a name="input_existing_subscription_name"></a> [existing\_subscription\_name](#input\_existing\_subscription\_name) | Name of existing Pub/Sub subscription to use. If empty, creates new subscription | `string` | `""` | no |
| <a name="input_existing_topic_name"></a> [existing\_topic\_name](#input\_existing\_topic\_name) | Name of existing Pub/Sub topic to use. If empty, creates new topic | `string` | `""` | no |
| <a name="input_folder_ids"></a> [folder\_ids](#input\_folder\_ids) | List of Google Cloud folders being registered | `list(string)` | `[]` | no |
| <a name="input_infra_project_id"></a> [infra\_project\_id](#input\_infra\_project\_id) | Project ID used for CrowdStrike infrastructure resources (topic, subscription, and other components). Defaults to WIF project if not specified | `string` | `""` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Map of labels to be applied to all resources created by this module | `map(string)` | `{}` | no |
| <a name="input_message_retention_duration"></a> [message\_retention\_duration](#input\_message\_retention\_duration) | Message retention duration for Pub/Sub subscription (e.g., '604800s' for 7 days) | `string` | `"604800s"` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | The Google Cloud organization being registered | `string` | `""` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | List of Google Cloud projects being registered | `list(string)` | `[]` | no |
| <a name="input_registration_id"></a> [registration\_id](#input\_registration\_id) | Unique registration ID returned by CrowdStrike Registration API | `string` | n/a | yes |
| <a name="input_registration_type"></a> [registration\_type](#input\_registration\_type) | The scope of the Google Cloud registration which can be one of the following values: organization, folder, project | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix to be added to all created resource names for identification | `string` | `""` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Suffix to be added to all created resource names for identification | `string` | `""` | no |
| <a name="input_schema_definition"></a> [schema\_definition](#input\_schema\_definition) | Avro or Protocol Buffer schema definition (required if enable\_schema\_validation is true) | `string` | `""` | no |
| <a name="input_schema_type"></a> [schema\_type](#input\_schema\_type) | Schema type: 'AVRO' or 'PROTOCOL\_BUFFER' | `string` | `"AVRO"` | no |
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