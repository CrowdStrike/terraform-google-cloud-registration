locals {
  folder_list = var.folder_ids

  # Effective IAM roles for the current registration scope:
  # - org/folder: universal + org-level roles
  # - project: universal + project-level roles
  effective_iam_roles = concat(
    var.google_iam_roles,
    var.registration_type == "project" ? var.google_iam_roles_project_level : var.google_iam_roles_org_level
  )
}

# IAM bindings for organization-level registration
resource "google_organization_iam_member" "crowdstrike_organization" {
  for_each = toset(var.registration_type == "organization" ? local.effective_iam_roles : [])

  org_id = var.organization_id
  role   = each.value
  member = var.wif_iam_principal
}

# IAM bindings for folder-level registration
resource "google_folder_iam_member" "crowdstrike_folder" {
  for_each = toset([
    for pair in setproduct(
      var.registration_type == "folder" ? local.folder_list : [],
      local.effective_iam_roles
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
      var.registration_type == "project" ? var.project_ids : [],
      local.effective_iam_roles
    ) : "${pair[0]}::${pair[1]}"
  ])

  project = split("::", each.key)[0]
  role    = split("::", each.key)[1]
  member  = var.wif_iam_principal
}

# Enable required APIs for CrowdStrike WIF project
resource "google_project_service" "asset_inventory_apis" {
  for_each = var.manage_wif_project_apis ? toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudasset.googleapis.com"
  ]) : []

  project                    = var.wif_project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}
