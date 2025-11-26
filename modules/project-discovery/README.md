<!-- BEGIN_TF_DOCS -->
![CrowdStrike Project Discovery Terraform Module for GCP](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

## Introduction

This Terraform module discovers Google Cloud projects for CrowdStrike's Cloud Security Posture Management (CSPM) registration based on the specified scope (organization, folder, or project). It identifies active projects within the GCP hierarchy.

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

module "project_discovery" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/project-discovery"

  # Registration Scope - Organization Level
  registration_type = "organization"
  organization_id   = "123456789012"

  # Optional: Folder registration (alternative to organization)
  # registration_type = "folder"
  # folder_ids = ["123456789", "987654321"]

  # Optional: Project registration (alternative to organization/folder)
  # registration_type = "project"
  # project_ids = ["project-1", "project-2", "project-3"]
}
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.0 |
## Resources

| Name | Type |
|------|------|
| [google_projects.folder_projects](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/projects) | data source |
| [google_projects.org_projects](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/projects) | data source |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_folder_ids"></a> [folder\_ids](#input\_folder\_ids) | List of Google Cloud folders being registered | `list(string)` | `[]` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | GCP Organization ID for organization-level registration | `string` | `""` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | List of Google Cloud projects being registered | `list(string)` | `[]` | no |
| <a name="input_registration_type"></a> [registration\_type](#input\_registration\_type) | Type of registration: organization, folder, or project | `string` | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_discovered_projects"></a> [discovered\_projects](#output\_discovered\_projects) | Combined list of all discovered/specified projects based on registration type |
<!-- END_TF_DOCS -->
