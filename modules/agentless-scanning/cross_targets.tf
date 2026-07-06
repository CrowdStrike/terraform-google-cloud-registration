# =============================================================================
# Cross-Project Target Resources (cross mode only)
# =============================================================================

# =============================================================================
# Org mode: single org-level custom role + binding
# =============================================================================

# Protects org-level target role against 44-day soft-delete collision
resource "random_id" "target_gcs_role_org_suffix" {
  count       = local.is_org_registration ? 1 : 0
  byte_length = 4
}

resource "google_organization_iam_custom_role" "target_scanner_gcs_role" {
  count = local.is_org_registration ? 1 : 0

  org_id      = var.organization_id
  role_id     = "${local.scanner_gcs_role.id_prefix}_${local.role_suffix}_${random_id.target_gcs_role_org_suffix[0].hex}"
  title       = local.scanner_gcs_role.title
  description = local.scanner_gcs_role.description

  permissions = local.scanner_gcs_role.permissions
}

resource "google_organization_iam_member" "target_scanner_gcs_permissions" {
  count = local.is_org_registration ? 1 : 0

  org_id = var.organization_id
  role   = google_organization_iam_custom_role.target_scanner_gcs_role[0].id
  member = "serviceAccount:${google_service_account.scanner_sa[var.host_project_id].email}"
}

# =============================================================================
# Multi-project (standalone cross) mode: per-target-project custom role + binding
# =============================================================================
# Only used for project registrations in cross mode (cross_target_ids is empty
# for org/folder, which bind a single org-level role instead).

# Protects per-target-project role against 44-day soft-delete collision
resource "random_id" "target_gcs_role_suffix" {
  for_each    = toset(local.cross_target_ids)
  byte_length = 4
}

resource "google_project_iam_custom_role" "target_scanner_gcs_role" {
  for_each = toset(local.cross_target_ids)

  project     = each.value
  role_id     = "${local.scanner_gcs_role.id_prefix}_${local.role_suffix}_${random_id.target_gcs_role_suffix[each.value].hex}"
  title       = local.scanner_gcs_role.title
  description = local.scanner_gcs_role.description

  permissions = local.scanner_gcs_role.permissions
}

resource "google_project_iam_member" "target_scanner_gcs_permissions" {
  for_each = toset(local.cross_target_ids)

  project = each.value
  role    = google_project_iam_custom_role.target_scanner_gcs_role[each.value].id
  member  = "serviceAccount:${google_service_account.scanner_sa[var.host_project_id].email}"
}

# =============================================================================
# Folder + cross + org-level role: single org role bound at folder level
# =============================================================================
# This avoids listing individual project IDs — the role is created at the org
# and the binding at the folder inherits to all projects underneath.

resource "random_id" "folder_org_role_suffix" {
  count       = local.is_folder_registration ? 1 : 0
  byte_length = 4
}

resource "google_organization_iam_custom_role" "folder_scanner_gcs_role" {
  count = local.is_folder_registration ? 1 : 0

  org_id      = var.folder_org_id
  role_id     = "${local.scanner_gcs_role.id_prefix}_${local.role_suffix}_${random_id.folder_org_role_suffix[0].hex}"
  title       = local.scanner_gcs_role.title
  description = local.scanner_gcs_role.description

  permissions = local.scanner_gcs_role.permissions
}

resource "google_folder_iam_member" "folder_scanner_gcs_permissions" {
  for_each = local.is_folder_registration ? toset(var.folder_ids) : toset([])

  folder = "folders/${each.value}"
  role   = google_organization_iam_custom_role.folder_scanner_gcs_role[0].id
  member = "serviceAccount:${google_service_account.scanner_sa[var.host_project_id].email}"
}
