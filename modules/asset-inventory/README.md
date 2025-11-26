<!-- BEGIN_TF_DOCS -->
![CrowdStrike Asset Inventory Terraform Module for GCP](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

## Introduction

This Terraform module configures Google Cloud IAM permissions required for CrowdStrike's Cloud Security Posture Management (CSPM) asset inventory scanning. It grants the necessary viewer roles to CrowdStrike's federated identity at the organization, folder, or project level, and enables required Google Cloud APIs for asset discovery and security assessment.

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

module "asset_inventory" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/asset-inventory"

  # CrowdStrike IAM Principal (from workload-identity module output)
  wif_iam_principal = "principal://iam.googleapis.com/projects/123456789/locations/global/workloadIdentityPools/cs-wif-pool-12345/subject/arn:aws:sts::532730071073:assumed-role/CrowdStrikeCSPMConnector/unique-registration-id"

  # Registration Scope - Organization Level
  registration_type = "organization"
  organization_id   = "123456789012"

  # Projects discovered by project-discovery module
  discovered_projects = [
    "project-1",
    "project-2",
    "project-3"
  ]

  # Optional: Folder registration (alternative to organization)
  # registration_type = "folder"
  # folder_ids = ["123456789", "987654321"]

  # Optional: Project registration (alternative to organization/folder)
  # registration_type = "project"
  # project_ids = ["project-1", "project-2"]
}
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.0 |
## Resources

| Name | Type |
|------|------|
| [google_folder_iam_member.crowdstrike_folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_organization_iam_member.crowdstrike_organization](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_project_iam_member.crowdstrike_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.asset_inventory_apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_discovered_projects"></a> [discovered\_projects](#input\_discovered\_projects) | List of all discovered projects where APIs will be enabled | `list(string)` | n/a | yes |
| <a name="input_folder_ids"></a> [folder\_ids](#input\_folder\_ids) | List of Google Cloud folders being registered | `list(string)` | `[]` | no |
| <a name="input_google_iam_roles"></a> [google\_iam\_roles](#input\_google\_iam\_roles) | List of Google Cloud IAM roles that will be granted to the wif\_iam\_principal identity for asset inventory access | `list(string)` | <pre>[<br/>  "roles/browser",<br/>  "roles/cloudasset.viewer",<br/>  "roles/aiplatform.viewer",<br/>  "roles/alloydb.viewer",<br/>  "roles/apigee.readOnlyAdmin",<br/>  "roles/appengine.appViewer",<br/>  "roles/cloudtasks.viewer",<br/>  "roles/compute.viewer",<br/>  "roles/dataplex.viewer",<br/>  "roles/essentialcontacts.viewer",<br/>  "roles/firebaseappcheck.viewer",<br/>  "roles/firebaseauth.viewer",<br/>  "roles/firebasedatabase.viewer",<br/>  "roles/firebasehosting.viewer",<br/>  "roles/firebasestorage.viewer",<br/>  "roles/notebooks.viewer",<br/>  "roles/recommender.iampolicychangeriskViewer",<br/>  "roles/recommender.iamViewer",<br/>  "roles/securitycenter.adminViewer",<br/>  "roles/cloudfunctions.developer"<br/>]</pre> | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | The Google Cloud organization being registered | `string` | `null` | no |
| <a name="input_registration_type"></a> [registration\_type](#input\_registration\_type) | The scope of the Google Cloud registration which can be one of the following values: organization, folder, project | `string` | n/a | yes |
| <a name="input_wif_iam_principal"></a> [wif\_iam\_principal](#input\_wif\_iam\_principal) | Google Cloud IAM Principal that identifies CrowdStrike resources | `string` | n/a | yes |
## Outputs

No outputs.
<!-- END_TF_DOCS -->
