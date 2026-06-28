<!-- BEGIN_TF_DOCS -->
![CrowdStrike Agentless Scanning Terraform Module for GCP](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

## Introduction

This Terraform module provisions Google Cloud infrastructure for CrowdStrike's agentless scanning capabilities (DSPM). It creates scanner service accounts, networking (VPC, subnets, optional Cloud NAT), IAM custom roles with least-privilege permissions, and Secret Manager secrets for Falcon credentials. The module supports single-project, multi-project (cross-project), folder, and organization registration scopes.

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
  project = "your-infrastructure-project"
}

module "agentless_scanning" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/agentless-scanning"

  # Registration context
  registration_type = "project"
  registration_id   = "unique-registration-id"

  # Project scope
  host_project_id  = "your-infrastructure-project"
  project_ids      = ["your-infrastructure-project"]
  is_cross_project = false

  # Workload Identity Federation
  wif_project_number        = "123456789"
  wif_pool_id               = "cs-wif-pool-12345"
  agentless_scanning_role_arn = "arn:aws:sts::111111111111:assumed-role/CrowdStrikeScannerRole"

  # Falcon credentials
  falcon_client_id     = "<Falcon API client ID>"
  falcon_client_secret = "<Falcon API client secret>"

  # Scanning regions
  regions = ["us-east1"]

  # Optional: Resource naming
  resource_prefix = "cs-"
  resource_suffix = "-prod"
}
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.7.1 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |
## Resources

| Name | Type |
|------|------|
| [google_compute_network.agentless_vpc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_router.agentless_router](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router) | resource |
| [google_compute_router_nat.agentless_nat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_router_nat) | resource |
| [google_compute_subnetwork.agentless_subnet](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork_iam_member.wif_byo_subnet_network_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork_iam_member) | resource |
| [google_compute_subnetwork_iam_member.wif_subnet_network_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork_iam_member) | resource |
| [google_folder_iam_member.folder_scanner_gcs_permissions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_folder_iam_member.wif_viewer_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_organization_iam_custom_role.folder_scanner_gcs_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_custom_role) | resource |
| [google_organization_iam_custom_role.target_scanner_gcs_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_custom_role) | resource |
| [google_organization_iam_member.target_scanner_gcs_permissions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_organization_iam_member.wif_viewer_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_project_iam_custom_role.scanner_gcs_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.target_scanner_gcs_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_custom_role.wif_compute_role](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_custom_role) | resource |
| [google_project_iam_member.scanner_gcs_permissions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.target_scanner_gcs_permissions](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.wif_compute](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.wif_viewer_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.wif_viewer_roles_project_only](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.required_apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.serviceusage](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_secret_manager_secret.falcon_credentials](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_iam_member.scanner_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_version.falcon_credentials](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_service_account.scanner_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.wif_can_use_scanner_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [random_id.folder_org_role_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.gcs_role_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.infra_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.target_gcs_role_org_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.target_gcs_role_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [terraform_data.agentless_validation](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [google_compute_subnetwork.byo_validation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork) | data source |
| [google_project_ancestry.host_project_scope_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project_ancestry) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agentless_scanning_role_arn"></a> [agentless\_scanning\_role\_arn](#input\_agentless\_scanning\_role\_arn) | AWS Role ARN used by CrowdStrike agentless scanning for authentication via WIF | `string` | n/a | yes |
| <a name="input_custom_vpc_configuration"></a> [custom\_vpc\_configuration](#input\_custom\_vpc\_configuration) | Custom VPC configuration for the host project. When set, uses the provided VPC/subnets instead of creating a managed VPC. vpc\_name = VPC name, subnets = {region = subnet\_name}. | <pre>object({<br/>    vpc_name = string<br/>    subnets  = map(string)<br/>  })</pre> | `null` | no |
| <a name="input_deploy_cloud_nat"></a> [deploy\_cloud\_nat](#input\_deploy\_cloud\_nat) | Deploy Cloud NAT for scanner VMs. true = private IPs + NAT, false = public IPs. | `bool` | `true` | no |
| <a name="input_falcon_client_id"></a> [falcon\_client\_id](#input\_falcon\_client\_id) | Falcon API client ID for scanner authentication | `string` | n/a | yes |
| <a name="input_falcon_client_secret"></a> [falcon\_client\_secret](#input\_falcon\_client\_secret) | Falcon API client secret for scanner authentication | `string` | n/a | yes |
| <a name="input_folder_ids"></a> [folder\_ids](#input\_folder\_ids) | List of Google Cloud folder IDs for folder-level registration | `list(string)` | `[]` | no |
| <a name="input_folder_org_id"></a> [folder\_org\_id](#input\_folder\_org\_id) | Parent GCP Organization ID of the registered folder(s). Required for folder registration to host the org-level scanner custom role bound at folder scope. | `string` | `null` | no |
| <a name="input_host_project_id"></a> [host\_project\_id](#input\_host\_project\_id) | Google Cloud Project ID hosting the agentless scanning infrastructure (the host project). Set only in cross-project mode (org/folder/multi-project); null for per-project (no-cross) registrations where each project self-hosts. | `string` | `null` | no |
| <a name="input_is_cross_project"></a> [is\_cross\_project](#input\_is\_cross\_project) | Cross-project scanning mode. true = 1 host project + targets get scan permissions only. false = every target project gets full scanning infra. Org/folder registrations must always be cross-project. | `bool` | `true` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Map of labels to be applied to all resources that support them | `map(string)` | `{}` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | GCP Organization ID for organization-level registration | `string` | `null` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | List of registered project IDs (full registration scope). Used for viewer role bindings and cross/no-cross target derivation. | `list(string)` | `[]` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | GCP regions to deploy scanner infrastructure (VPC, subnets, NAT). | `set(string)` | `[]` | no |
| <a name="input_registration_id"></a> [registration\_id](#input\_registration\_id) | Unique registration ID from CrowdStrike backend. Used as suffix for resources with soft-delete lifecycle (SA, custom roles). | `string` | n/a | yes |
| <a name="input_registration_type"></a> [registration\_type](#input\_registration\_type) | Type of registration: organization, folder, or project | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix to be added to created resource names | `string` | `""` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Suffix to be added to created resource names | `string` | `""` | no |
| <a name="input_wif_pool_id"></a> [wif\_pool\_id](#input\_wif\_pool\_id) | Workload Identity Pool ID from the shared CSPM WIF pool | `string` | n/a | yes |
| <a name="input_wif_project_number"></a> [wif\_project\_number](#input\_wif\_project\_number) | GCP Project Number for the WIF project (used in principal construction) | `string` | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agentless_infra"></a> [agentless\_infra](#output\_agentless\_infra) | Per-project infrastructure map for agentless scanning provider settings |
| <a name="output_agentless_wif_principal"></a> [agentless\_wif\_principal](#output\_agentless\_wif\_principal) | WIF Principal string for agentless scanning IAM bindings |
| <a name="output_cross_target_ids"></a> [cross\_target\_ids](#output\_cross\_target\_ids) | Target project IDs with cross-project GCS scanning permissions |
| <a name="output_deployment_version"></a> [deployment\_version](#output\_deployment\_version) | Module deployment version for BE tracking |
| <a name="output_host_project_ids"></a> [host\_project\_ids](#output\_host\_project\_ids) | GCP host project IDs (single project in cross mode, multiple in no-cross) |
| <a name="output_scanner_sa_emails"></a> [scanner\_sa\_emails](#output\_scanner\_sa\_emails) | Scanner Service Account emails per host project |
<!-- END_TF_DOCS -->