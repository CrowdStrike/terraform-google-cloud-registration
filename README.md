<!-- BEGIN_TF_DOCS -->
![CrowdStrike Registration terraform module](https://raw.githubusercontent.com/CrowdStrike/falconpy/main/docs/asset/cs-logo.png)

[![Twitter URL](https://img.shields.io/twitter/url?label=Follow%20%40CrowdStrike&style=social&url=https%3A%2F%2Ftwitter.com%2FCrowdStrike)](https://twitter.com/CrowdStrike)

## Introduction

This Terraform module enables registration and configuration of Google Cloud Platform (GCP) organizations, folders, and projects with CrowdStrike's Falcon Cloud Security. It provides a solution for integrating GCP environments with CrowdStrike's cloud security services, including Workload Identity Federation setup, asset inventory configuration, and real-time visibility through log ingestion.

Key features:
- Workload Identity Federation for secure, keyless authentication
- Asset Inventory configuration for organization, folder, and project scopes
- Real-time visibility with log ingestion (Audit Logs via Pub/Sub)
- Automatic discovery of projects within organizations and folders

## Pre-requisites
### Generate API Keys

CrowdStrike API keys are required to use this module. It is highly recommended that you create a dedicated API client with only the required scopes.

1. In the CrowdStrike console, navigate to **Support and resources** > **API Clients & Keys**. Click **Add new API Client**.
2. Add the required scopes for your deployment:

<table>
    <tr>
        <th>Option</th>
        <th>Scope Name</th>
        <th>Permission</th>
    </tr>
    <tr>
        <td rowspan="2">Automated account registration</td>
        <td>CSPM registration</td>
        <td><strong>Read</strong> and <strong>Write</strong></td>
    </tr>
    <tr>
        <td>Cloud Security Google Cloud Registration</td>
        <td><strong>Read</strong> and <strong>Write</strong></td>
    </tr>
</table>

3. Click **Add** to create the API client. The next screen will display the API **CLIENT ID**, **SECRET**, and **BASE URL**. You will need all three for the next step.

    <details><summary>picture</summary>
    <p>

    ![api-client-keys](https://github.com/CrowdStrike/aws-ssm-distributor/blob/main/official-package/assets/api-client-keys.png)

    </p>
    </details>

> [!NOTE]
> This page is only shown once. Make sure you copy **CLIENT ID**, **SECRET**, and **BASE URL** to a secure location.

## Usage

```hcl
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
}

module "crowdstrike_gcp_registration" {
  source = "CrowdStrike/terraform-google-cloud-registration"

  # GCP configuration - You can use organizations, folders, projects, or combinations
  registration_type = "organization"      # or "folder" or "project"
  organization_id   = "123456789012"      # Required for organization registration
  # folder_ids      = ["folder1", "folder2"]  # Required for folder registration
  # project_ids     = ["project-1", "project-2"]  # Required for project registration

  # GCP project that will host CrowdStrike infrastructure
  infra_project_id = "my-security-project"

  # CrowdStrike API configuration
  falcon_client_id     = "<Falcon API client ID>"
  falcon_client_secret = "<Falcon API client secret>"

  # AWS integration (CrowdStrike's identity federation)
  role_arn = "arn:aws:sts::532730071073:assumed-role/CrowdStrikeCSPMConnector"

  # Optional: Enable Real Time Visibility and Detection
  enable_realtime_visibility = true

  # Optional: Configure log ingestion settings
  log_ingestion_settings = {
    message_retention_duration       = "1209600s"  # 14 days
    ack_deadline_seconds             = 300         # 5 minutes
    topic_message_retention_duration = "2592000s"  # 30 days
    audit_log_types                  = ["activity", "system_event", "policy"]
    exclusion_filters = [
      "resource.labels.environment=\"test\"",
      "resource.labels.temporary=\"true\""
    ]
  }

  # Optional: Resource naming customization
  resource_prefix = "cs-"
  resource_suffix = "-prod"

  # Optional: Custom labels
  labels = {
    environment = "production"
    project     = "crowdstrike-integration"
    managed-by  = "terraform"
  }
}
```

<!-- END_TF_DOCS -->