<!-- BEGIN_TF_DOCS -->
![CrowdStrike Workload Identity Terraform Module for GCP](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

## Introduction

This Terraform module creates and configures Google Cloud Workload Identity Federation (WIF) resources required for CrowdStrike's cloud security services. It establishes a secure trust relationship between your Google Cloud environment and CrowdStrike's AWS-based infrastructure, enabling CrowdStrike to access your GCP resources for security monitoring without requiring long-lived service account keys.

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

module "workload_identity" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/workload-identity"

  # GCP Project Configuration
  wif_project_id = "your-csmp-infrastructure-project"

  # Workload Identity Pool Configuration
  wif_pool_id          = "cs-wif-pool-12345"
  wif_pool_provider_id = "cs-provider-12345"

  # CrowdStrike Role ARN
  role_arn = "arn:aws:sts::111111111111:assumed-role/CrowdStrikeConnectorRoleName"

  # Registration ID
  registration_id = "unique-registration-id"

  # Optional: Resource Naming
  resource_prefix = "cs-"
  resource_suffix = "-prod"
}
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.0 |
## Resources

| Name | Type |
|------|------|
| [google_iam_workload_identity_pool.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.aws](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_project_service.required_apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project_service.serviceusage](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_project.wif_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_registration_id"></a> [registration\_id](#input\_registration\_id) | Unique registration ID returned by CrowdStrike Registration API | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix to be added to all created resource names for identification | `string` | `null` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Suffix to be added to all created resource names for identification | `string` | `null` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | AWS Role ARN used by CrowdStrike for authentication | `string` | n/a | yes |
| <a name="input_wif_pool_id"></a> [wif\_pool\_id](#input\_wif\_pool\_id) | Google Cloud Workload Identity Federation Pool ID that is used to identify a CrowdStrike identity pool | `string` | n/a | yes |
| <a name="input_wif_pool_provider_id"></a> [wif\_pool\_provider\_id](#input\_wif\_pool\_provider\_id) | Google Cloud Workload Identity Federation Provider ID that is used to identify the CrowdStrike provider | `string` | n/a | yes |
| <a name="input_wif_project_id"></a> [wif\_project\_id](#input\_wif\_project\_id) | Google Cloud Project ID where the CrowdStrike workload identity federation pool resources are deployed | `string` | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_wif_iam_principal"></a> [wif\_iam\_principal](#output\_wif\_iam\_principal) | Google Cloud IAM Principal that identifies the specific CrowdStrike session for this registration |
| <a name="output_wif_pool_id"></a> [wif\_pool\_id](#output\_wif\_pool\_id) | The ID of the Workload Identity Pool |
| <a name="output_wif_pool_provider_id"></a> [wif\_pool\_provider\_id](#output\_wif\_pool\_provider\_id) | The ID of the Workload Identity Pool Provider |
| <a name="output_wif_project_id"></a> [wif\_project\_id](#output\_wif\_project\_id) | Project ID for the WIF Project |
| <a name="output_wif_project_number"></a> [wif\_project\_number](#output\_wif\_project\_number) | Project number for the WIF Project ID |
<!-- END_TF_DOCS -->
