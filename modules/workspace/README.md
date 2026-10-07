<!-- BEGIN_TF_DOCS -->
![CrowdStrike Workspace Terraform Module for GCP](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

## Introduction

This Terraform module creates the Google Cloud resources that CrowdStrike uses to read your Google Workspace directory. It enables the Admin SDK, Cloud Identity, Cloud Resource Manager and IAM APIs, and creates one service account. It lets the CrowdStrike Workspace identity of this registration impersonate that service account through Workload Identity Federation (WIF). By default it also grants `roles/resourcemanager.organizationViewer` on your organization to the service account, so that CrowdStrike can verify that the organization belongs to the Workspace.

A principal that can change IAM policies or create service account keys in the WIF project can also act as the service account. Use a WIF project where only administrators have these rights.

The deployer needs `roles/iam.serviceAccountAdmin` and `roles/serviceusage.serviceUsageAdmin` on the WIF project. For the organization grant, the deployer also needs `resourcemanager.organizations.getIamPolicy` and `resourcemanager.organizations.setIamPolicy` on the organization. Without them, the first apply fails with a 403 after the other resources exist. After the grant is in the state, every plan reads the organization IAM policy, so a later deployer without `getIamPolicy` fails at plan. To deploy without organization IAM rights, set `grant_organization_viewer = false`, and ask an organization admin to grant `roles/resourcemanager.organizationViewer` to the `sa_email` output.

## Manual step after the apply

In the Google Workspace Admin Console, a super admin must assign a **custom** admin role with read-only access to Users, Groups and organizational units to the `sa_email` output. Terraform does not make this assignment, because it needs super admin credentials. `terraform destroy` does not remove it.

## Usage

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = "your-wif-project"
}

module "workspace" {
  source = "CrowdStrike/terraform-google-cloud-registration//modules/workspace"

  # Project that holds the Workspace WIF pool
  wif_project_id = "your-wif-project"

  # Account ID of the Workspace service account, as given by CrowdStrike
  service_account_id = "csgws-0123456789a"

  # CrowdStrike Workspace principal (from workload-identity module output)
  workspace_wif_principal = "principal://iam.googleapis.com/projects/123456789/locations/global/workloadIdentityPools/cs-wif-pool-12345/subject/arn:aws:sts::111111111111:assumed-role/CrowdStrikeWorkspaceReader/unique-registration-id"

  # Organization linked to the Workspace, with no organizations/ prefix
  organization_id = "123456789012"

  # Optional: set to false when an organization admin makes the grant by hand
  grant_organization_viewer = true
}
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 5.0 |
## Resources

| Name | Type |
|------|------|
| [google_organization_iam_member.workspace_org_viewer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_project_service.workspace_apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |
| [google_service_account.workspace_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.wif_can_impersonate](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_grant_organization_viewer"></a> [grant\_organization\_viewer](#input\_grant\_organization\_viewer) | Grant roles/resourcemanager.organizationViewer on the organization to the Workspace service account. Set to false only when an organization admin makes the grant by hand | `bool` | `true` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | GCP organization ID linked to the Workspace, with no organizations/ prefix | `string` | n/a | yes |
| <a name="input_service_account_id"></a> [service\_account\_id](#input\_service\_account\_id) | Account ID of the Workspace service account. CrowdStrike computes it from the Workspace registration ID and shows the email before the apply, so pass the value unchanged | `string` | n/a | yes |
| <a name="input_wif_project_id"></a> [wif\_project\_id](#input\_wif\_project\_id) | Google Cloud Project ID that hosts the Workspace Workload Identity Federation pool and the Workspace service account | `string` | n/a | yes |
| <a name="input_workspace_wif_principal"></a> [workspace\_wif\_principal](#input\_workspace\_wif\_principal) | Subject-scoped principal:// URI of the CrowdStrike Workspace identity for this registration. Use the wif\_iam\_principal output of the workload-identity module | `string` | n/a | yes |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sa_email"></a> [sa\_email](#output\_sa\_email) | Email of the Workspace service account. In the Admin Console, assign it a custom read-only admin role |
| <a name="output_sa_unique_id"></a> [sa\_unique\_id](#output\_sa\_unique\_id) | Numeric unique ID of the Workspace service account |
<!-- END_TF_DOCS -->
