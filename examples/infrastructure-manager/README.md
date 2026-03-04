<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_crowdstrike"></a> [crowdstrike](#requirement\_crowdstrike) | >= 0.0.50 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 5.45.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_crowdstrike_gcp_registration"></a> [crowdstrike\_gcp\_registration](#module\_crowdstrike\_gcp\_registration) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [google_secret_manager_secret_version.falcon_client_secret](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/secret_manager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployment_method"></a> [deployment\_method](#input\_deployment\_method) | Deployment method for the CrowdStrike GCP registration | `string` | `"terraform-native"` | no |
| <a name="input_enable_realtime_visibility"></a> [enable\_realtime\_visibility](#input\_enable\_realtime\_visibility) | Enable Real Time Visibility & Detection features (requires log ingestion setup) | `bool` | `false` | no |
| <a name="input_falcon_client_id"></a> [falcon\_client\_id](#input\_falcon\_client\_id) | Falcon API client ID. | `string` | n/a | yes |
| <a name="input_falcon_client_secret"></a> [falcon\_client\_secret](#input\_falcon\_client\_secret) | Falcon API client secret. If not provided, will be retrieved from Secret Manager. | `string` | `null` | no |
| <a name="input_falcon_client_secret_name"></a> [falcon\_client\_secret\_name](#input\_falcon\_client\_secret\_name) | Name of the Secret Manager secret containing the Falcon API client secret | `string` | `"crowdstrike-falcon-client-secret"` | no |
| <a name="input_folder_ids"></a> [folder\_ids](#input\_folder\_ids) | List of Google Cloud folders being registered | `list(string)` | `[]` | no |
| <a name="input_infra_project_id"></a> [infra\_project\_id](#input\_infra\_project\_id) | GCP Project ID where CrowdStrike infrastructure will be created (WIF pools, Pub/Sub topics, etc.) | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to all created resources | `map(string)` | `{}` | no |
| <a name="input_log_ingestion_settings"></a> [log\_ingestion\_settings](#input\_log\_ingestion\_settings) | Configuration settings for log ingestion. Controls Pub/Sub topic and subscription settings, audit log types, schema validation, and allows using existing resources. | <pre>object({<br/>    message_retention_duration       = optional(string, "604800s")<br/>    ack_deadline_seconds             = optional(number, 600)<br/>    topic_message_retention_duration = optional(string, "604800s")<br/>    audit_log_types                  = optional(list(string), ["activity", "system_event", "policy"])<br/>    topic_storage_regions            = optional(list(string), [])<br/>    enable_schema_validation         = optional(bool, false)<br/>    schema_type                      = optional(string, "AVRO")<br/>    schema_definition                = optional(string)<br/>    existing_topic_name              = optional(string)<br/>    existing_subscription_name       = optional(string)<br/>    exclusion_filters                = optional(list(string), [])<br/>  })</pre> | `{}` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | GCP Organization ID for organization-level registration | `string` | `null` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | List of GCP Project IDs to register with CrowdStrike CSPM | `list(string)` | `[]` | no |
| <a name="input_registration_name"></a> [registration\_name](#input\_registration\_name) | Name for the CrowdStrike GCP registration | `string` | n/a | yes |
| <a name="input_registration_type"></a> [registration\_type](#input\_registration\_type) | Type of registration: organization, folder, or project | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix for resource names (helps with organization and identification) | `string` | `null` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Suffix for resource names (helps with organization and identification) | `string` | `null` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | AWS IAM Role ARN for CrowdStrike identity federation | `string` | n/a | yes |
| <a name="input_wif_project_id"></a> [wif\_project\_id](#input\_wif\_project\_id) | Google Cloud Project ID where the CrowdStrike workload identity federation pool resources are deployed. Defaults to infra\_project\_id if not specified | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_log_sink_names"></a> [log\_sink\_names](#output\_log\_sink\_names) | Names of the created log sinks (if RTV&D enabled) |
| <a name="output_log_subscription_name"></a> [log\_subscription\_name](#output\_log\_subscription\_name) | The full resource name of the Pub/Sub subscription for log ingestion (if RTV&D enabled) |
| <a name="output_log_topic_name"></a> [log\_topic\_name](#output\_log\_topic\_name) | The full resource name of the Pub/Sub topic for log ingestion (if RTV&D enabled) |
| <a name="output_registration_id"></a> [registration\_id](#output\_registration\_id) | The unique CrowdStrike registration ID for this GCP setup |
| <a name="output_wif_project_id"></a> [wif\_project\_id](#output\_wif\_project\_id) | The GCP Project ID where Workload Identity resources were created |
| <a name="output_wif_project_number"></a> [wif\_project\_number](#output\_wif\_project\_number) | The GCP Project Number for the Workload Identity project |
<!-- END_TF_DOCS -->
