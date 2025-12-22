<!-- BEGIN_TF_DOCS -->
## Description

This Terraform module provides automated registration and configuration of Google Cloud Platform (GCP) organizations, folders, and projects with CrowdStrike's Cloud Security Posture Management (CSPM) platform.

The module enables keyless authentication through GCP's Workload Identity Federation and provides security monitoring capabilities including asset inventory and optional real-time log ingestion for threat detection.

### Key Features

- **Multi-Scope Registration**: Support for organization, folder, and project-level registrations
- **Workload Identity Federation**: Secure, keyless authentication using GCP's identity federation  
- **Asset Inventory**: Monitoring of GCP resources for security posture assessment
- **Real Time Visibility & Detection** (Optional): Real-time log streaming for threat detection

### Architecture Overview

The module creates the following GCP resources:
- Workload Identity Pool and Provider for authentication
- IAM role bindings for CrowdStrike service principals across target scopes
- Pub/Sub topics and subscriptions for log ingestion (when RTV&D is enabled)
- Log sinks for audit log streaming (when RTV&D is enabled)

### Prerequisites

Before using this module, ensure you have:

1. **CrowdStrike Requirements**:
   - Falcon Console access with CSPM enabled
   - API credentials with `CSPM registration (Read & Write)` and `Cloud Security Google Cloud Registration (Read & Write)` scopes

2. **GCP Requirements**:
   - GCP project for CrowdStrike infrastructure resources
   - Appropriate IAM permissions for the deployment service account
   - Required GCP APIs enabled

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
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_crowdstrike"></a> [crowdstrike](#provider\_crowdstrike) | ~> 0.0.53 |
| <a name="provider_google.wif"></a> [google.wif](#provider\_google.wif) | ~> 5.0 |
## Resources

| Name | Type |
|------|------|
| [crowdstrike_cloud_google_registration.main](https://registry.terraform.io/providers/crowdstrike/crowdstrike/latest/docs/resources/cloud_google_registration) | resource |
| [crowdstrike_cloud_google_registration_settings.main](https://registry.terraform.io/providers/crowdstrike/crowdstrike/latest/docs/resources/cloud_google_registration_settings) | resource |
| [google_project.wif_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployment_method"></a> [deployment\_method](#input\_deployment\_method) | Deployment method for the CrowdStrike GCP registration | `string` | `"terraform-native"` | no |
| <a name="input_enable_realtime_visibility"></a> [enable\_realtime\_visibility](#input\_enable\_realtime\_visibility) | Enable Real Time Visibility and Detection (RTV&D) features via log ingestion | `bool` | `false` | no |
| <a name="input_excluded_project_patterns"></a> [excluded\_project\_patterns](#input\_excluded\_project\_patterns) | List of regex patterns to exclude specific projects from CSPM registration. Projects matching these patterns will be excluded from asset inventory and log ingestion. | `list(string)` | `[]` | no |
| <a name="input_folder_ids"></a> [folder\_ids](#input\_folder\_ids) | List of Google Cloud folders being registered | `list(string)` | `[]` | no |
| <a name="input_infra_project_id"></a> [infra\_project\_id](#input\_infra\_project\_id) | Google Cloud Project ID where CrowdStrike infrastructure resources will be deployed | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Map of labels to be applied to all resources created by this module | `map(string)` | `{}` | no |
| <a name="input_log_ingestion_settings"></a> [log\_ingestion\_settings](#input\_log\_ingestion\_settings) | Configuration settings for log ingestion. Controls Pub/Sub topic and subscription settings, audit log types, schema validation, and allows using existing resources. | <pre>object({<br/>    message_retention_duration       = optional(string, "604800s")<br/>    ack_deadline_seconds             = optional(number, 600)<br/>    topic_message_retention_duration = optional(string, "604800s")<br/>    audit_log_types                  = optional(list(string), ["activity", "system_event", "policy"])<br/>    topic_storage_regions            = optional(list(string), [])<br/>    enable_schema_validation         = optional(bool, false)<br/>    schema_type                      = optional(string, "AVRO")<br/>    schema_definition                = optional(string)<br/>    existing_topic_name              = optional(string)<br/>    existing_subscription_name       = optional(string)<br/>    exclusion_filters                = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | GCP Organization ID for organization-level registration | `string` | `null` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | List of Google Cloud projects being registered | `list(string)` | `[]` | no |
| <a name="input_registration_name"></a> [registration\_name](#input\_registration\_name) | Name for the CrowdStrike GCP registration | `string` | n/a | yes |
| <a name="input_registration_type"></a> [registration\_type](#input\_registration\_type) | Type of registration: organization, folder, or project | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix to be added to all created resource names for identification | `string` | `null` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Suffix to be added to all created resource names for identification | `string` | `null` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | AWS Role ARN used by CrowdStrike for authentication | `string` | n/a | yes |
| <a name="input_wif_project_id"></a> [wif\_project\_id](#input\_wif\_project\_id) | Google Cloud Project ID where the CrowdStrike workload identity federation pool resources are deployed. Defaults to infra\_project\_id if not specified | `string` | `null` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_discovered_projects"></a> [discovered\_projects](#output\_discovered\_projects) | Detailed information about discovered and registered projects |
| <a name="output_log_sink_names"></a> [log\_sink\_names](#output\_log\_sink\_names) | Names of the created log sinks (if RTV&D enabled) |
| <a name="output_log_subscription_id"></a> [log\_subscription\_id](#output\_log\_subscription\_id) | The ID of the Pub/Sub subscription for log ingestion (if RTV&D enabled) |
| <a name="output_log_topic_id"></a> [log\_topic\_id](#output\_log\_topic\_id) | The ID of the Pub/Sub topic for log ingestion (if RTV&D enabled) |
| <a name="output_registration_id"></a> [registration\_id](#output\_registration\_id) | The unique CrowdStrike registration ID for this GCP setup |
| <a name="output_wif_iam_principal"></a> [wif\_iam\_principal](#output\_wif\_iam\_principal) | The IAM principal that CrowdStrike uses to access GCP resources |
| <a name="output_wif_pool_id"></a> [wif\_pool\_id](#output\_wif\_pool\_id) | The ID of the created Workload Identity Pool |
| <a name="output_wif_pool_provider_id"></a> [wif\_pool\_provider\_id](#output\_wif\_pool\_provider\_id) | The ID of the created Workload Identity Pool Provider |
| <a name="output_wif_project_id"></a> [wif\_project\_id](#output\_wif\_project\_id) | The GCP Project ID where Workload Identity resources were created |
| <a name="output_wif_project_number"></a> [wif\_project\_number](#output\_wif\_project\_number) | The GCP Project Number for the Workload Identity project |
<!-- END_TF_DOCS -->
