<!-- BEGIN_TF_DOCS -->
![CrowdStrike Asset Inventory Terraform Module for GCP](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

## Introduction

This Terraform module configures Google Cloud IAM permissions required for CrowdStrike's Cloud Security Posture Management (CSPM) asset inventory scanning. It grants the necessary viewer roles to CrowdStrike's federated identity at the organization, folder, or project level, and enables required Google Cloud APIs for asset discovery and security assessment.

**Key Features:**
- **IAM Permission Configuration**: Grants viewer roles for asset scanning  
- **API Enablement**: Enables required APIs across target projects for scanning
- **Registration Scopes**: Supports organization, folder, or project-level registration

## Usage

```hcl
terraform {
  required_version = ">= 1.0"
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

# Configure asset inventory permissions
module "asset_inventory" {
  source = "CrowdStrike/cloud-registration/gcp//modules/asset-inventory"

  # Required: Workload Identity Federation principal from workload-identity module
  wif_iam_principal = module.workload_identity.wif_iam_principal

  # Required: Projects discovered by project-discovery module
  discovered_projects = module.project_discovery.discovered_projects
  
  # Required: Registration configuration
  registration_type = "organization"
  organization_id   = "123456789012"

  # Optional: Customize IAM roles (uses CrowdStrike defaults if not specified)
  # google_iam_roles = [
  #   "roles/browser",
  #   "roles/cloudasset.viewer",
  #   # ... additional roles
  # ]
}
```

## Project Configuration

This module configures IAM permissions and API enablement for the specified projects:

```hcl
module "asset_inventory" {
  source = "CrowdStrike/cloud-registration/gcp//modules/asset-inventory"
  
  wif_iam_principal   = module.workload_identity.wif_iam_principal
  discovered_projects = module.project_discovery.discovered_projects
  registration_type   = "organization"
  organization_id     = "123456789012"
}
```

## IAM Roles Granted

This module grants the following IAM roles to CrowdStrike's federated identity for asset inventory scanning:

**Core Viewer Roles:**
- `roles/browser` - Browse GCP resources hierarchy
- `roles/cloudasset.viewer` - View Cloud Asset Inventory
- `roles/securitycenter.adminViewer` - View Security Command Center findings

**Service-specific Viewer Roles:**
- `roles/aiplatform.viewer` - AI Platform resources
- `roles/alloydb.viewer` - AlloyDB resources
- `roles/apigee.readOnlyAdmin` - Apigee API management
- `roles/appengine.appViewer` - App Engine applications
- `roles/cloudtasks.viewer` - Cloud Tasks
- `roles/compute.viewer` - Compute Engine resources
- `roles/dataplex.viewer` - Dataplex data governance
- `roles/essentialcontacts.viewer` - Essential contacts
- `roles/firebaseappcheck.viewer` - Firebase App Check
- `roles/firebaseauth.viewer` - Firebase Authentication
- `roles/firebasedatabase.viewer` - Firebase Realtime Database
- `roles/firebasehosting.viewer` - Firebase Hosting
- `roles/firebasestorage.viewer` - Firebase Storage
- `roles/notebooks.viewer` - AI Platform Notebooks
- `roles/recommender.iampolicychangeriskViewer` - IAM policy risk insights
- `roles/recommender.iamViewer` - IAM recommendations
- `roles/cloudfunctions.developer` - Cloud Functions

## APIs Enabled

The module automatically enables these Google Cloud APIs across all relevant projects for asset scanning:

**Core APIs** (enabled on all discovered/specified projects):
- `iam.googleapis.com` - Identity and Access Management API
- `iamcredentials.googleapis.com` - IAM Service Account Credentials API  
- `cloudresourcemanager.googleapis.com` - Cloud Resource Manager API
- `cloudasset.googleapis.com` - Cloud Asset API

This ensures CrowdStrike can perform asset inventory scanning across your entire GCP infrastructure scope.

## Security Considerations

- **Least Privilege**: Only viewer-level permissions are granted
- **Scoped Access**: Permissions are limited to the specified registration scope
- **Federated Identity**: Uses Workload Identity Federation, no service account keys
- **Audit Trail**: All access is logged through Cloud Audit Logs
- **API Enablement**: Only enables APIs necessary for asset inventory scanning

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [google_project_iam_member.crowdstrike_project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.asset_inventory_apis](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_discovered_projects"></a> [discovered\_projects](#input\_discovered\_projects) | List of all discovered projects where APIs will be enabled | `list(string)` | n/a | yes |
| <a name="input_folder_ids"></a> [folder\_ids](#input\_folder\_ids) | Comma separated list of the Google Cloud folders being registered | `string` | `""` | no |
| <a name="input_google_iam_roles"></a> [google\_iam\_roles](#input\_google\_iam\_roles) | List of Google Cloud IAM roles that will be granted to the wif_iam_principal identity for asset inventory access | `list(string)` | `[default CrowdStrike roles]` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | The Google Cloud organization being registered | `string` | `""` | no |
| <a name="input_project_ids"></a> [project\_ids](#input\_project\_ids) | Comma separated list of the Google Cloud projects being registered | `string` | `""` | no |
| <a name="input_registration_type"></a> [registration\_type](#input\_registration\_type) | The scope of the Google Cloud registration which can be one of the following values: organization, folder, project | `string` | n/a | yes |
| <a name="input_wif_iam_principal"></a> [wif\_iam\_principal](#input\_wif\_iam\_principal) | Google Cloud IAM Principal that identifies CrowdStrike resources | `string` | n/a | yes |

## Outputs

This module does not define any outputs.

<!-- END_TF_DOCS -->