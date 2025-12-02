locals {
  folder_list  = var.folder_ids
  project_list = var.project_ids

  # Discover projects for organization registration
  discovered_org_projects = var.registration_type == "organization" && var.organization_id != "" ? try([for project in data.google_projects.org_projects[0].projects : project.project_id], []) : []

  # Discover projects for folder registration
  discovered_folder_projects = var.registration_type == "folder" ? flatten([
    for folder_id in local.folder_list : [
      for project in data.google_projects.folder_projects[folder_id].projects : project.project_id
    ]
  ]) : []

  # Combined list of all projects
  all_projects = var.registration_type == "organization" ? local.discovered_org_projects : (
    var.registration_type == "folder" ? local.discovered_folder_projects : local.project_list
  )
}

# Discover all projects in organization
data "google_projects" "org_projects" {
  count  = var.registration_type == "organization" && var.organization_id != "" ? 1 : 0
  filter = "parent.id:${var.organization_id} parent.type:organization lifecycleState:ACTIVE"
}

# Discover projects in each folder
data "google_projects" "folder_projects" {
  for_each = toset(var.registration_type == "folder" ? local.folder_list : [])
  filter   = "parent.id:${each.value} parent.type:folder lifecycleState:ACTIVE"
}
