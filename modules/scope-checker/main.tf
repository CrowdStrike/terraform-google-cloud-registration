# Data source to check if infra_project_id is within folder registration scope
data "google_project_ancestry" "infra_project" {
  count   = var.registration_type == "folder" ? 1 : 0
  project = var.infra_project_id
}

locals {
  # Extract folder IDs from infra project's ancestors
  infra_project_folder_ancestors = var.registration_type == "folder" ? [
    for ancestor in data.google_project_ancestry.infra_project[0].ancestors :
    ancestor.id if ancestor.type == "folder"
  ] : []

  # Check if any target folder is an ancestor of infra_project_id
  infra_project_in_scope = var.registration_type == "folder" ? length(setintersection(
    toset(var.folder_ids),
    toset(local.infra_project_folder_ancestors)
  )) > 0 : true
}
