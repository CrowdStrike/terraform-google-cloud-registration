locals {
  folder_list = var.folder_ids
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
      var.registration_type == "project" ? var.project_ids : [],
      var.google_iam_roles
    ) : "${pair[0]}::${pair[1]}"
  ])

  project = split("::", each.key)[0]
  role    = split("::", each.key)[1]
  member  = var.wif_iam_principal
}

# Enable required APIs for CrowdStrike WIF project
resource "google_project_service" "asset_inventory_apis" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudasset.googleapis.com"
  ])

  project                    = var.wif_project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}
