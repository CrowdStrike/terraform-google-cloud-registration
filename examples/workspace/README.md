<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.22 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_crowdstrike_gws_registration"></a> [crowdstrike\_gws\_registration](#module\_crowdstrike\_gws\_registration) | ../../workspace | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_customer_id"></a> [customer\_id](#input\_customer\_id) | Google Workspace customer ID, with no customers/ prefix. | `string` | n/a | yes |
| <a name="input_grant_organization_viewer"></a> [grant\_organization\_viewer](#input\_grant\_organization\_viewer) | Grant roles/resourcemanager.organizationViewer on organization\_id to the Workspace service account. | `bool` | `true` | no |
| <a name="input_gws_identity_source"></a> [gws\_identity\_source](#input\_gws\_identity\_source) | Identity source of the registration, as given by the CrowdStrike console: aws-sts or gcp-oidc. | `string` | n/a | yes |
| <a name="input_gws_registration_id"></a> [gws\_registration\_id](#input\_gws\_registration\_id) | ID of the CrowdStrike Google Workspace registration, as given by the CrowdStrike console. | `string` | n/a | yes |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | ID of the GCP organization that belongs to the Google Workspace, with no organizations/ prefix. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix for the display names of the WIF pool and provider. | `string` | `null` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Suffix for the display names of the WIF pool and provider. | `string` | `null` | no |
| <a name="input_service_account_id"></a> [service\_account\_id](#input\_service\_account\_id) | Account ID of the Workspace service account, as given by the CrowdStrike console. | `string` | n/a | yes |
| <a name="input_wif_pool_id"></a> [wif\_pool\_id](#input\_wif\_pool\_id) | ID of the Workload Identity Pool, as given by the CrowdStrike console. | `string` | n/a | yes |
| <a name="input_wif_project_id"></a> [wif\_project\_id](#input\_wif\_project\_id) | Google Cloud Project ID that holds the Workspace WIF pool and service account. | `string` | n/a | yes |
| <a name="input_wif_provider_id"></a> [wif\_provider\_id](#input\_wif\_provider\_id) | ID of the Workload Identity Pool Provider, as given by the CrowdStrike console. | `string` | n/a | yes |
| <a name="input_workspace_role_arn"></a> [workspace\_role\_arn](#input\_workspace\_role\_arn) | AWS Role ARN of the CrowdStrike Workspace reader, for aws-sts clouds. Set this or workspace\_service\_account\_unique\_id, not both. | `string` | `null` | no |
| <a name="input_workspace_service_account_unique_id"></a> [workspace\_service\_account\_unique\_id](#input\_workspace\_service\_account\_unique\_id) | Unique ID of the CrowdStrike Workspace intermediate service account, for gcp-oidc clouds. Set this or workspace\_role\_arn, not both. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_identity_pool_name"></a> [identity\_pool\_name](#output\_identity\_pool\_name) | Full resource name of the Workspace Workload Identity Pool. |
| <a name="output_project_number"></a> [project\_number](#output\_project\_number) | Project number of the WIF project. |
| <a name="output_provider_name"></a> [provider\_name](#output\_provider\_name) | Full resource name of the Workspace Workload Identity Pool Provider. |
| <a name="output_sa_email"></a> [sa\_email](#output\_sa\_email) | Email of the Workspace service account. In the Admin Console, assign it a custom read-only admin role. |
| <a name="output_sa_unique_id"></a> [sa\_unique\_id](#output\_sa\_unique\_id) | Numeric unique ID of the Workspace service account. |
| <a name="output_wif_principal"></a> [wif\_principal](#output\_wif\_principal) | WIF principal of the CrowdStrike Workspace identity for this registration. |
<!-- END_TF_DOCS -->