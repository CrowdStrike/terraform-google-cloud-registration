locals {
  folder_list  = var.folder_ids != "" ? split(",", var.folder_ids) : []
  project_list = var.project_ids != "" ? split(",", var.project_ids) : []
  
  # Discover projects for organization registration
  discovered_org_projects = var.registration_type == "organization" && var.organization_id != "" ? try([for project in data.google_projects.org_projects[0].projects : project.project_id], []) : []
  
  # Discover projects for folder registration
  discovered_folder_projects = var.registration_type == "folder" ? flatten([
    for folder_id in local.folder_list : [
      for project in data.google_projects.folder_projects[folder_id].projects : project.project_id
    ]
  ]) : []
  
  # Combined list of all projects for API enablement
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

# IAM bindings for organization-level registration
resource "google_organization_iam_member" "crowdstrike_organization" {
  for_each = toset(var.registration_type == "organization" ? var.google_iam_roles : [])

  org_id = var.organization_id
  role   = each.value
  member = var.wif_iam_principal
}

# IAM bindings for folder-level registration
resource "google_folder_iam_member" "crowdstrike_folder" {
  for_each = toset([
    for pair in setproduct(
      var.registration_type == "folder" ? local.folder_list : [],
      var.google_iam_roles
    ) : "${pair[0]}::${pair[1]}"
  ])

  folder = split("::", each.key)[0]
  role   = split("::", each.key)[1]
  member = var.wif_iam_principal
}

# IAM bindings for project-level registration
resource "google_project_iam_member" "crowdstrike_project" {
  for_each = toset([
    for pair in setproduct(
      var.registration_type == "project" ? local.project_list : [],
      var.google_iam_roles
    ) : "${pair[0]}::${pair[1]}"
  ])

  project = split("::", each.key)[0]
  role    = split("::", each.key)[1]
  member  = var.wif_iam_principal
}

# Enable required APIs for asset inventory scanning
resource "google_project_service" "asset_inventory_apis" {
  for_each = toset([
    for pair in setproduct(
      local.all_projects,
      ["iam.googleapis.com", "iamcredentials.googleapis.com", "cloudresourcemanager.googleapis.com", "cloudasset.googleapis.com"]
    ) : "${pair[0]}::${pair[1]}"
  ])

  project = split("::", each.key)[0]
  service = split("::", each.key)[1]
  disable_dependent_services = false
  disable_on_destroy         = true

  timeouts {
    create = "5m"
  }
}