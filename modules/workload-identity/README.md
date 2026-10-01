<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_iam_workload_identity_pool.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.aws](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_iam_workload_identity_pool_provider.oidc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_project_service.required_apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.serviceusage](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project.wif_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_agentless_scanning_service_account_unique_id"></a> [agentless\_scanning\_service\_account\_unique\_id](#input\_agentless\_scanning\_service\_account\_unique\_id) | Numeric unique ID of CrowdStrike's agentless scanning service account. Included in OIDC attribute\_condition when provided. | `string` | `null` | no |
| <a name="input_identity_source"></a> [identity\_source](#input\_identity\_source) | Identity federation type: aws-sts (AWS role ARN) or gcp-oidc (GCP service account) | `string` | n/a | yes |
| <a name="input_registration_id"></a> [registration\_id](#input\_registration\_id) | Unique registration ID returned by CrowdStrike Registration API | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix to be added to all created resource names for identification | `string` | `null` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Suffix to be added to all created resource names for identification | `string` | `null` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | AWS Role ARN used by CrowdStrike for authentication. Required when identity\_source is aws-sts. | `string` | `null` | no |
| <a name="input_service_account_unique_id"></a> [service\_account\_unique\_id](#input\_service\_account\_unique\_id) | Numeric unique ID of CrowdStrike's shared service account. Required when identity\_source is gcp-oidc. | `string` | `null` | no |
| <a name="input_wif_pool_id"></a> [wif\_pool\_id](#input\_wif\_pool\_id) | Google Cloud Workload Identity Federation Pool ID that is used to identify a CrowdStrike identity pool | `string` | n/a | yes |
| <a name="input_wif_pool_provider_id"></a> [wif\_pool\_provider\_id](#input\_wif\_pool\_provider\_id) | Google Cloud Workload Identity Federation Provider ID that is used to identify the CrowdStrike provider | `string` | n/a | yes |
| <a name="input_wif_project_id"></a> [wif\_project\_id](#input\_wif\_project\_id) | Google Cloud Project ID where the CrowdStrike workload identity federation pool resources are deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_wif_iam_principal"></a> [wif\_iam\_principal](#output\_wif\_iam\_principal) | Google Cloud IAM Principal that identifies the specific CrowdStrike session for this registration |
| <a name="output_wif_pool_id"></a> [wif\_pool\_id](#output\_wif\_pool\_id) | The ID of the Workload Identity Pool |
| <a name="output_wif_pool_name"></a> [wif\_pool\_name](#output\_wif\_pool\_name) | Name of the Workload Identity Pool |
| <a name="output_wif_pool_provider_id"></a> [wif\_pool\_provider\_id](#output\_wif\_pool\_provider\_id) | The ID of the Workload Identity Pool Provider |
| <a name="output_wif_project_id"></a> [wif\_project\_id](#output\_wif\_project\_id) | Project ID for the WIF Project |
| <a name="output_wif_project_number"></a> [wif\_project\_number](#output\_wif\_project\_number) | Project number for the WIF Project ID |
| <a name="output_wif_provider_name"></a> [wif\_provider\_name](#output\_wif\_provider\_name) | Name of the Workload Identity Pool Provider |
<!-- END_TF_DOCS -->
