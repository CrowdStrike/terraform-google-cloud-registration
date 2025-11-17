# Log Ingestion Module Examples

This directory contains Terraform examples demonstrating various configurations of the CrowdStrike log-ingestion module for Google Cloud Platform.

## Prerequisites

Before using these examples, ensure you have:

1. **Workload Identity Federation configured** - Use the `workload-identity` module first
2. **Appropriate IAM permissions** for the user/service account running Terraform to:
   - Enable APIs in the target project
   - Create Pub/Sub topics and subscriptions
   - Create logging sinks
   - Manage IAM bindings

> **Note**: The module automatically enables required GCP APIs including Cloud Logging, Pub/Sub, IAM, and others.

## Examples Overview

### 1. [Project Registration](./project-registration/)
Basic log ingestion setup for a single GCP project.

**Use case**: Small organizations or single-project deployments
**Features**: 
- Minimal configuration
- Project-level audit log collection
- Basic retention settings

### 2. [Folder Registration](./folder-registration/)
Log ingestion for specific GCP folders and their contained projects.

**Use case**: Department or team-level log collection
**Features**:
- Multi-folder support
- Custom exclusion filters
- Folder-scoped resource naming

### 3. [Organization Registration](./organization-registration/)
Organization-wide log ingestion with advanced filtering and retention.

**Use case**: Enterprise deployments
**Features**:
- Full organization coverage
- Extended retention periods
- Comprehensive exclusion filters
- Custom resource naming

### 4. [Existing Pub/Sub Resources](./existing-pubsub-resources/)
Integration with pre-existing Pub/Sub topic and subscription.

**Use case**: Organizations with existing log infrastructure
**Features**:
- Reuses existing Pub/Sub resources
- IAM binding configuration only
- No new resource creation

### 5. [Advanced Configuration](./advanced-configuration/)
Comprehensive example showcasing all module features.

**Use case**: Large enterprises with complex requirements
**Features**:
- Schema validation with AVRO
- Multi-region storage
- All audit log types including data access
- Complex exclusion filters
- Extended compliance retention

## Common Configuration Patterns

### WIF Principal Format
All examples use this format for the Workload Identity Federation principal:
```
principal://iam.googleapis.com/projects/{PROJECT_NUMBER}/locations/global/workloadIdentityPools/{POOL_ID}/subject/arn:aws:sts::{AWS_ACCOUNT}:assumed-role/{ROLE_NAME}/{SESSION_NAME}
```

### Resource Naming
The module creates resources with this naming pattern:
- **Topic**: `{prefix}CrowdStrikeLogTopic-{registration_id}{suffix}`
- **Subscription**: `{prefix}CrowdStrikeLogSubscription-{registration_id}{suffix}`  
- **Log Sink**: `{prefix}CrowdStrikeLogSink{suffix}`

### Audit Log Types
- **activity**: Admin activity and configuration changes
- **system_event**: System-generated events  
- **policy**: IAM policy changes
- **data_access**: Data read/write operations (high volume)

## Quick Start

1. Update the hardcoded values:
   - `wif_iam_principal`: From your workload-identity module output
   - `registration_id`: From CrowdStrike Registration API
   - Project/organization/folder IDs
   - `crowdstrike_infra_project_id`: Where Pub/Sub resources will be created
2. Customize optional settings as needed
3. Run `terraform init && terraform plan && terraform apply`
