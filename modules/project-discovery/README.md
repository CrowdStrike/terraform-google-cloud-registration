# Project Discovery Module

Discovers Google Cloud projects for CrowdStrike CSPM registration based on scope:
- **Organization**: All active projects in the organization
- **Folder**: All active projects in specified folders  
- **Project**: Explicitly provided project IDs

## Usage

```hcl
module "project_discovery" {
  source = "./modules/project-discovery"
  
  registration_type = "organization"
  organization_id   = "123456789012"
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| registration_type | `organization`, `folder`, or `project` | `string` | yes |
| organization_id | 12-digit organization ID | `string` | if org |
| folder_ids | List of 12-digit folder IDs | `list(string)` | if folder |
| project_ids | List of project IDs | `list(string)` | if project |

## Outputs

| Name | Description |
|------|-------------|
| discovered_projects | List of project IDs based on registration type |