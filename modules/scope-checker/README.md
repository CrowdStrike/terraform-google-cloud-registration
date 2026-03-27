# Scope Checker Module

This module determines whether the infrastructure project is within the registration scope for folder-based registrations.

## Purpose

When registering a folder in GCP CSPM, the infrastructure project (where Pub/Sub resources are created) might be either:
- Inside the registered folder scope (inherited permissions)  
- Outside the registered folder scope (requires explicit project-level permissions)

This module performs the scope check and returns a boolean result that other modules can use for conditional resource creation.

## Usage

```hcl
module "scope-checker" {
  source = "./modules/scope-checker/"

  registration_type = "folder"
  folder_ids        = ["123456789"]
  infra_project_id  = "my-infra-project"
}

output "in_scope" {
  value = module.scope-checker.infra_project_in_scope
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| registration_type | Registration scope (organization/folder/project) | `string` | n/a | yes |
| folder_ids | List of folder IDs being registered | `list(string)` | `[]` | no |
| infra_project_id | Infrastructure project ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| infra_project_in_scope | Whether the infra project is within registration scope |

<!-- BEGIN_TF_DOCS -->
# Scope Checker Module

This module determines whether the infrastructure project is within the registration scope for folder-based registrations.

When registering a folder in GCP CSPM, the infrastructure project (where Pub/Sub resources are created) might be either inside or outside the registered folder scope. This module performs the scope check and returns a boolean result for conditional IAM resource creation.

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
  project = "your-cspm-infrastructure-project"
}

module "scope_checker" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/scope-checker"

  # Registration configuration
  registration_type = "folder"
  folder_ids        = ["904504220746"]
  infra_project_id  = "my-infra-project"
}

# Use the output to conditionally create resources
output "project_in_scope" {
  description = "Whether the infrastructure project is within registration scope"
  value       = module.scope_checker.infra_project_in_scope
}
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.22.0 |
## Resources

| Name | Type |
|------|------|
| [google_project_ancestry.infra_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project_ancestry) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_folder_ids"></a> [folder\_ids](#input\_folder\_ids) | List of Google Cloud folders being registered | `list(string)` | `[]` | no |
| <a name="input_infra_project_id"></a> [infra\_project\_id](#input\_infra\_project\_id) | Project ID used for CrowdStrike infrastructure resources | `string` | n/a | yes |
| <a name="input_registration_type"></a> [registration\_type](#input\_registration\_type) | The scope of the Google Cloud registration which can be one of the following values: organization, folder, project | `string` | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_infra_project_in_scope"></a> [infra\_project\_in\_scope](#output\_infra\_project\_in\_scope) | Boolean indicating whether the infrastructure project is within the registration scope |
<!-- END_TF_DOCS -->
