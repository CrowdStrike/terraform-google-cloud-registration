<!-- BEGIN_TF_DOCS -->
## Description

This root module creates the Google Cloud resources that let CrowdStrike read a Google Workspace directory through the Admin SDK Directory API, with no key: a Workload Identity Federation pool trusts only the CrowdStrike Workspace identity of this registration, and that identity impersonates one service account.

The Workspace has its own pool and its own service account. They are apart from the pool of the Google Cloud registration, and this module does not change the Google Cloud registration.

### Resources

The module creates these Google Cloud resources:
- A Workload Identity Pool, and one AWS or OIDC provider for the CrowdStrike Workspace identity
- The Admin SDK, Cloud Identity, Cloud Resource Manager and IAM APIs in the WIF project
- One service account, and one `roles/iam.workloadIdentityUser` binding for the WIF principal
- By default, one `roles/resourcemanager.organizationViewer` binding on `organization_id` for the service account

### Before the apply

The CrowdStrike console gives the Terraform inputs. Do not change `gws_registration_id`, `wif_pool_id`, `wif_provider_id`, `gws_identity_source`, `wif_project_id` or `service_account_id`: CrowdStrike authenticates against these values.

The `--enable-workspace` option of `scripts/service-account-setup.sh` prepares the deployer service account. The option takes no scope flag. The deployer needs:
- `roles/iam.workloadIdentityPoolAdmin`, `roles/iam.serviceAccountAdmin` and `roles/serviceusage.serviceUsageAdmin` on the WIF project
- `resourcemanager.organizations.get` on `organization_id`, for the link check
- `resourcemanager.organizations.getIamPolicy` and `resourcemanager.organizations.setIamPolicy` on `organization_id`, when `grant_organization_viewer = true`

`roles/iam.serviceAccountAdmin` applies to every service account in the WIF project, so the deployer can act as any of them. If one of them has organization roles, the deployer can get those roles too.

The script gives the first two items, and neither `getIamPolicy` nor `setIamPolicy`. With the script, set `grant_organization_viewer = false`, and after the apply, ask an organization admin to grant `roles/resourcemanager.organizationViewer` on the organization to the `sa_email` output. The setup command from the CrowdStrike console sets this value and makes this grant. A deployer without `resourcemanager.organizations.setIamPolicy` gets a 403 at the first apply when `grant_organization_viewer = true`, after the other resources exist. After the binding is in the state, every plan reads the organization IAM policy, so a later deployer without `resourcemanager.organizations.getIamPolicy` fails at plan.

### The link check

The plan reads `organization_id` and compares its Workspace customer ID with `customer_id`. When the two do not match, the plan fails and names both values. Correct one of the two values. When the organization has no Workspace customer ID, the plan fails with a different message. A 403 on the organization read means that `organization_id` is wrong or that the deployer does not have `resourcemanager.organizations.get` on it.

### Manual step after the apply

Terraform does not assign the Google Workspace admin role, because the assignment needs super admin credentials. After the apply, a Workspace super admin must do these steps:

1. Open the Google Workspace Admin Console, then **Admin roles**.
2. Make a **custom** role with read-only access to Users, Groups and organizational units. Do not use a prebuilt role.
3. Assign the role to the service account by its email address. The `sa_email` output gives the email.

`terraform destroy` does not remove this role assignment. Remove it in the Admin Console. A binding that an organization admin made by hand also stays. Remove it by hand.

## Usage

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.22"
    }
  }
}

provider "google" {
  project = "your-wif-project"
}

module "crowdstrike_gws_registration" {
  source = "CrowdStrike/terraform-google-cloud-registration//workspace"

  # Registration values, as given by the CrowdStrike console
  gws_registration_id = "0123abcd-4567-89ef-0123-456789abcdef"
  wif_pool_id         = "cs-fcs-wif-0123456789abcdef"
  wif_provider_id     = "cs-provider-0123456789abcdef"
  gws_identity_source = "aws-sts"
  service_account_id  = "csgws-0123abcd456"

  # Workspace identity: workspace_role_arn (aws-sts) or workspace_service_account_unique_id (gcp-oidc)
  workspace_role_arn = "arn:aws:sts::111111111111:assumed-role/CrowdStrikeWorkspaceReader"

  # The WIF project of the Google Cloud registration
  wif_project_id = "your-wif-project"

  # The organization and the Workspace that it belongs to
  organization_id = "123456789012"
  customer_id     = "C01abc23x"
}
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.22 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
## Resources

| Name | Type |
|------|------|
| [terraform_data.gws_registration](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [google_organization.link_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/organization) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_customer_id"></a> [customer\_id](#input\_customer\_id) | Google Workspace customer ID, for example C01abc23x, with no customers/ prefix. The plan fails when it does not belong to organization\_id. | `string` | n/a | yes |
| <a name="input_grant_organization_viewer"></a> [grant\_organization\_viewer](#input\_grant\_organization\_viewer) | Grant roles/resourcemanager.organizationViewer on organization\_id to the Workspace service account. Set to false only when an organization admin makes this grant by hand. | `bool` | `true` | no |
| <a name="input_gws_identity_source"></a> [gws\_identity\_source](#input\_gws\_identity\_source) | Identity source of the registration, as given by CrowdStrike: aws-sts or gcp-oidc. | `string` | n/a | yes |
| <a name="input_gws_registration_id"></a> [gws\_registration\_id](#input\_gws\_registration\_id) | ID of the CrowdStrike Google Workspace registration. It is the last part of the WIF principal subject and, for gcp-oidc, the OIDC audience. | `string` | n/a | yes |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | ID of the GCP organization that belongs to the Google Workspace, with no organizations/ prefix. | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix to be added to the display names of the WIF pool and provider. Combined length of prefix + suffix must not exceed 13 characters. | `string` | `null` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Suffix to be added to the display names of the WIF pool and provider. Combined length of prefix + suffix must not exceed 13 characters. | `string` | `null` | no |
| <a name="input_service_account_id"></a> [service\_account\_id](#input\_service\_account\_id) | Account ID of the Workspace service account, as given by CrowdStrike. The Admin Console role assignment uses the email that this ID gives. | `string` | n/a | yes |
| <a name="input_wif_pool_id"></a> [wif\_pool\_id](#input\_wif\_pool\_id) | ID of the Workload Identity Pool, as given by CrowdStrike. Do not make your own value: CrowdStrike authenticates against this ID. | `string` | n/a | yes |
| <a name="input_wif_project_id"></a> [wif\_project\_id](#input\_wif\_project\_id) | Google Cloud Project ID that holds the Workspace WIF pool and the Workspace service account. It is the WIF project of the Google Cloud registration. | `string` | n/a | yes |
| <a name="input_wif_provider_id"></a> [wif\_provider\_id](#input\_wif\_provider\_id) | ID of the Workload Identity Pool Provider, as given by CrowdStrike. | `string` | n/a | yes |
| <a name="input_workspace_role_arn"></a> [workspace\_role\_arn](#input\_workspace\_role\_arn) | AWS Role ARN used by the CrowdStrike Workspace reader for authentication via WIF. Set this or workspace\_service\_account\_unique\_id, not both. | `string` | `null` | no |
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