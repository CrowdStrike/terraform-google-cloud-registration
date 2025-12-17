<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_crowdstrike"></a> [crowdstrike](#requirement\_crowdstrike) | ~> 0.0.50 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_crowdstrike"></a> [crowdstrike](#provider\_crowdstrike) | 0.0.50 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_asset-inventory"></a> [asset-inventory](#module\_asset-inventory) | ../../modules/asset-inventory/ | n/a |
| <a name="module_log-ingestion"></a> [log-ingestion](#module\_log-ingestion) | ../../modules/log-ingestion/ | n/a |
| <a name="module_project-discovery"></a> [project-discovery](#module\_project-discovery) | ../../modules/project-discovery/ | n/a |
| <a name="module_workload-identity"></a> [workload-identity](#module\_workload-identity) | ../../modules/workload-identity/ | n/a |

## Resources

| Name | Type |
|------|------|
| [crowdstrike_cloud_google_registration.main](https://registry.terraform.io/providers/crowdstrike/crowdstrike/latest/docs/resources/cloud_google_registration) | resource |
| [crowdstrike_cloud_google_registration_logging_settings.main](https://registry.terraform.io/providers/crowdstrike/crowdstrike/latest/docs/resources/cloud_google_registration_logging_settings) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_realtime_visibility"></a> [enable\_realtime\_visibility](#input\_enable\_realtime\_visibility) | Enable Real Time Visibility & Detection features (requires log ingestion setup) | `bool` | `false` | no |
| <a name="input_falcon_client_id"></a> [falcon\_client\_id](#input\_falcon\_client\_id) | Falcon API client ID. | `string` | n/a | yes |
| <a name="input_falcon_client_secret"></a> [falcon\_client\_secret](#input\_falcon\_client\_secret) | Falcon API client secret. | `string` | n/a | yes |
| <a name="input_folder_ids"></a> [folder\_ids](#input\_folder\_ids) | List of Google Cloud folders being registered | `list(string)` | `[]` | no |
| <a name="input_infra_project_id"></a> [infra\_project\_id](#input\_infra\_project\_id) | GCP Project ID where CrowdStrike infrastructure will be created (WIF pools, Pub/Sub topics, etc.) | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to all created resources | `map(string)` | `{}` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | GCP Organization ID for organization-level registration | `string` | `null` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | List of GCP Project IDs to register with CrowdStrike CSPM | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | GCP region for resource deployment | `string` | `"us-central1"` | no |
| <a name="input_registration_name"></a> [registration\_name](#input\_registration\_name) | Name for the CrowdStrike GCP registration | `string` | n/a | yes |
| <a name="input_registration_type"></a> [registration\_type](#input\_registration\_type) | Type of registration: organization, folder, or project | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix for resource names (helps with organization and identification) | `string` | `null` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Suffix for resource names (helps with organization and identification) | `string` | `null` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | AWS IAM Role ARN for CrowdStrike identity federation | `string` | n/a | yes |
| <a name="input_wif_project_id"></a> [wif\_project\_id](#input\_wif\_project\_id) | Google Cloud Project ID where the CrowdStrike workload identity federation pool resources are deployed. Defaults to infra\_project\_id if not specified | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_integration"></a> [aws\_integration](#output\_aws\_integration) | AWS integration details for CrowdStrike identity federation |
| <a name="output_deployment_timestamp"></a> [deployment\_timestamp](#output\_deployment\_timestamp) | Timestamp when the deployment was completed |
| <a name="output_discovered_projects"></a> [discovered\_projects](#output\_discovered\_projects) | Detailed information about discovered and registered projects |
| <a name="output_infra_project_id"></a> [infra\_project\_id](#output\_infra\_project\_id) | The GCP Project ID where CrowdStrike infrastructure was created |
| <a name="output_log_ingestion_enabled"></a> [log\_ingestion\_enabled](#output\_log\_ingestion\_enabled) | Whether Real Time Visibility & Detection log ingestion is enabled |
| <a name="output_log_sink_names"></a> [log\_sink\_names](#output\_log\_sink\_names) | Names of the created log sinks (if RTV&D enabled) |
| <a name="output_module_version"></a> [module\_version](#output\_module\_version) | Version information for tracking deployments |
| <a name="output_pubsub_subscription_id"></a> [pubsub\_subscription\_id](#output\_pubsub\_subscription\_id) | The ID of the Pub/Sub subscription for log ingestion (if RTV&D enabled) |
| <a name="output_pubsub_topic_id"></a> [pubsub\_topic\_id](#output\_pubsub\_topic\_id) | The ID of the Pub/Sub topic for log ingestion (if RTV&D enabled) |
| <a name="output_region"></a> [region](#output\_region) | The GCP region where resources were deployed |
| <a name="output_registered_project_ids"></a> [registered\_project\_ids](#output\_registered\_project\_ids) | List of GCP Project IDs that were registered with CrowdStrike |
| <a name="output_registration_id"></a> [registration\_id](#output\_registration\_id) | The unique CrowdStrike registration ID for this GCP setup |
| <a name="output_registration_type"></a> [registration\_type](#output\_registration\_type) | The type of registration (project, folder, or organization) |
| <a name="output_resource_labels"></a> [resource\_labels](#output\_resource\_labels) | Labels applied to all created resources |
| <a name="output_wif_iam_principal"></a> [wif\_iam\_principal](#output\_wif\_iam\_principal) | The IAM principal that CrowdStrike uses to access GCP resources |
| <a name="output_wif_pool_id"></a> [wif\_pool\_id](#output\_wif\_pool\_id) | The ID of the created Workload Identity Pool |
| <a name="output_wif_pool_provider_id"></a> [wif\_pool\_provider\_id](#output\_wif\_pool\_provider\_id) | The ID of the created Workload Identity Pool Provider |
| <a name="output_wif_project_id"></a> [wif\_project\_id](#output\_wif\_project\_id) | The GCP Project ID where Workload Identity resources were created |
| <a name="output_wif_project_number"></a> [wif\_project\_number](#output\_wif\_project\_number) | The GCP Project Number for the Workload Identity project |
<!-- END_TF_DOCS -->
