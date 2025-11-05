# Asset Inventory Module Examples

This directory contains examples showing how to use the asset-inventory module for different registration scenarios.

## Examples

### 1. Organization Registration (`organization-registration/`)
- Registers an entire GCP organization with CrowdStrike
- Automatically discovers all active projects in the organization
- Grants IAM permissions at the organization level
- **Use case**: Full organization-wide CSPM coverage

### 2. Folder Registration (`folder-registration/`)
- Registers specific folders and their contained projects
- Automatically discovers projects within the specified folders
- Grants IAM permissions at both folder and project levels
- **Use case**: Department or team-specific CSPM coverage

### 3. Project Registration (`project-registration/`)
- Registers only explicitly specified projects
- No automatic project discovery
- Grants IAM permissions at the project level only
- **Use case**: Limited scope or pilot CSPM deployment

## Prerequisites

Before running any example:

1. **Replace placeholder values** with your actual GCP and AWS identifiers:
   - `my-crowdstrike-project` → Your GCP project for CrowdStrike infrastructure
   - `123456789012` → Your 12-digit organization ID  
   - `111111111111` → Your folder ID
   - `my-specific-project` → Your project IDs
   - `crowdstrike-gcp-wif-role` → Your AWS IAM role name
   - `org-123` → Your unique registration ID

2. **Configure authentication**:
   ```bash
   gcloud auth application-default login
   ```

> **Note**: Required APIs are automatically enabled by the Terraform template

## Running an Example

1. Navigate to the desired example directory:
   ```bash
   cd examples/organization-registration/
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review and customize the configuration as needed

4. Plan the deployment:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```