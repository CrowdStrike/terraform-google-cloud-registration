<!-- BEGIN_TF_DOCS -->
![CrowdStrike Workload Identity Terraform Module for GCP](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

## Introduction

This Terraform module creates and configures Google Cloud Workload Identity Federation (WIF) resources required for CrowdStrike's cloud security services. It establishes a secure trust relationship between your Google Cloud environment and CrowdStrike's AWS-based infrastructure, enabling CrowdStrike to access your GCP resources for security monitoring without requiring long-lived service account keys.

## Usage

```hcl
terraform {
  required_version = ">= 1.2.0"
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

# Create workload identity federation resources
module "workload_identity" {
  source = "CrowdStrike/cloud-registration/gcp//modules/workload-identity"

  # Required: Project where WIF resources will be created
  wif_project_id = "my-security-project"

  # Required: Pool and provider IDs (supplied by CrowdStrike during registration)
  wif_pool_id          = "cs-fcs-wif-abcd1234efgh5678"
  wif_pool_provider_id = "cs-provider-abcd1234efgh5678"

  # Required: CrowdStrike's AWS account ID
  aws_account_id = "123456789012"

  # Required: Display names for the resources
  wif_pool_name          = "CrowdStrike-WIF-Pool"
  wif_pool_provider_name = "CrowdStrike-AWS-Provider"

  # Optional: Resource naming
  resource_prefix = "cs"
  resource_suffix = "prod"
}
```

## Resources Created

This module creates the following Google Cloud resources:

- **Workload Identity Pool**: Establishes the identity federation boundary
- **Workload Identity Pool Provider**: Configures trust with CrowdStrike's AWS account
- **Required APIs**: Enables necessary Google Cloud APIs automatically:
  - `serviceusage.googleapis.com` (Service Usage API)
  - `iamcredentials.googleapis.com` (IAM Service Account Credentials API)
  - `iam.googleapis.com` (Identity and Access Management API)
  - `sts.googleapis.com` (Security Token Service API)

## Security Considerations

- The module enables only the minimum required Google Cloud APIs
- Workload Identity Federation provides keyless authentication
- Trust is established only with the specified AWS account ID
- No long-lived credentials are stored or transmitted

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
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID to add as a trust relationship in the WIF Pool Provider | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix to be added to all created resource names for identification | `string` | `""` | no |
| <a name="input_resource_suffix"></a> [resource\_suffix](#input\_resource\_suffix) | Suffix to be added to all created resource names for identification | `string` | `""` | no |
| <a name="input_wif_pool_id"></a> [wif\_pool\_id](#input\_wif\_pool\_id) | Google Cloud Workload Identity Federation Pool ID that is used to identify a CrowdStrike identity pool | `string` | n/a | yes |
| <a name="input_wif_pool_name"></a> [wif\_pool\_name](#input\_wif\_pool\_name) | Display name for the CrowdStrike Workload Identity Federation Pool (max 32 characters) | `string` | n/a | yes |
| <a name="input_wif_pool_provider_id"></a> [wif\_pool\_provider\_id](#input\_wif\_pool\_provider\_id) | Google Cloud Workload Identity Federation Provider ID that is used to identify the CrowdStrike provider | `string` | n/a | yes |
| <a name="input_wif_pool_provider_name"></a> [wif\_pool\_provider\_name](#input\_wif\_pool\_provider\_name) | Display name for the CrowdStrike Workload Identity Federation Provider (max 32 characters) | `string` | n/a | yes |
| <a name="input_wif_project_id"></a> [wif\_project\_id](#input\_wif\_project\_id) | Google Cloud Project ID where the CrowdStrike workload identity federation pool resources are deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_wif_project_number"></a> [wif\_project\_number](#output\_wif\_project\_number) | Project number for the WIF Project ID |

<!-- END_TF_DOCS -->