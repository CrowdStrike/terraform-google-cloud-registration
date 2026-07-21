# =============================================================================
# Cross-Project Target Resources (cross mode only)
# =============================================================================

# =============================================================================
# DSPM: Org mode - single org-level GCS custom role + binding
# =============================================================================

# Protects org-level target role against 44-day soft-delete collision
resource "random_id" "target_gcs_role_org_suffix" {
  count       = var.enable_dspm && local.is_org_registration ? 1 : 0
  byte_length = 4
}

resource "google_organization_iam_custom_role" "target_scanner_gcs_role" {
  count = var.enable_dspm && local.is_org_registration ? 1 : 0

  org_id      = var.organization_id
  role_id     = "${local.scanner_gcs_role.id_prefix}_${local.role_suffix}_${random_id.target_gcs_role_org_suffix[0].hex}"
  title       = local.scanner_gcs_role.title
  description = local.scanner_gcs_role.description

  permissions = local.scanner_gcs_role.permissions
}

resource "google_organization_iam_member" "target_scanner_gcs_permissions" {
  count = var.enable_dspm && local.is_org_registration ? 1 : 0

  org_id = var.organization_id
  role   = google_organization_iam_custom_role.target_scanner_gcs_role[0].id
  member = "serviceAccount:${google_service_account.scanner_sa[var.host_project_id].email}"
}

# =============================================================================
# DSPM: Multi-project (standalone cross) mode - per-target-project GCS role + binding
# =============================================================================

# Protects per-target-project role against 44-day soft-delete collision
resource "random_id" "target_gcs_role_suffix" {
  for_each    = var.enable_dspm ? toset(local.cross_target_ids) : toset([])
  byte_length = 4
}

resource "google_project_iam_custom_role" "target_scanner_gcs_role" {
  for_each = var.enable_dspm ? toset(local.cross_target_ids) : toset([])

  project     = each.value
  role_id     = "${local.scanner_gcs_role.id_prefix}_${local.role_suffix}_${random_id.target_gcs_role_suffix[each.value].hex}"
  title       = local.scanner_gcs_role.title
  description = local.scanner_gcs_role.description

  permissions = local.scanner_gcs_role.permissions
}

resource "google_project_iam_member" "target_scanner_gcs_permissions" {
  for_each = var.enable_dspm ? toset(local.cross_target_ids) : toset([])

  project = each.value
  role    = google_project_iam_custom_role.target_scanner_gcs_role[each.value].id
  member  = "serviceAccount:${google_service_account.scanner_sa[var.host_project_id].email}"
}

# =============================================================================
# DSPM: Folder + cross + org-level role - single org role bound at folder level
# =============================================================================

resource "random_id" "folder_org_role_suffix" {
  count       = var.enable_dspm && local.is_folder_registration ? 1 : 0
  byte_length = 4
}

resource "google_organization_iam_custom_role" "folder_scanner_gcs_role" {
  count = var.enable_dspm && local.is_folder_registration ? 1 : 0

  org_id      = var.folder_org_id
  role_id     = "${local.scanner_gcs_role.id_prefix}_${local.role_suffix}_${random_id.folder_org_role_suffix[0].hex}"
  title       = local.scanner_gcs_role.title
  description = local.scanner_gcs_role.description

  permissions = local.scanner_gcs_role.permissions
}

resource "google_folder_iam_member" "folder_scanner_gcs_permissions" {
  for_each = var.enable_dspm && local.is_folder_registration ? toset(var.folder_ids) : toset([])

  folder = "folders/${each.value}"
  role   = google_organization_iam_custom_role.folder_scanner_gcs_role[0].id
  member = "serviceAccount:${google_service_account.scanner_sa[var.host_project_id].email}"
}

# =============================================================================
# Vulnerability Scanning: Org mode - org-level snapshot orchestrator role
# =============================================================================

resource "random_id" "target_vulnerability_role_org_suffix" {
  count       = var.enable_vulnerability_scanning && local.is_org_registration ? 1 : 0
  byte_length = 4
}

resource "google_organization_iam_custom_role" "target_vulnerability_snapshot_role" {
  count = var.enable_vulnerability_scanning && local.is_org_registration ? 1 : 0

  org_id      = var.organization_id
  role_id     = "${local.vulnerability_wif_target_role.id_prefix}_${local.role_suffix}_${random_id.target_vulnerability_role_org_suffix[0].hex}"
  title       = local.vulnerability_wif_target_role.title
  description = local.vulnerability_wif_target_role.description

  permissions = local.vulnerability_wif_target_role.permissions
}

resource "google_organization_iam_member" "target_vulnerability_snapshot_permissions" {
  count = var.enable_vulnerability_scanning && local.is_org_registration ? 1 : 0

  org_id = var.organization_id
  role   = google_organization_iam_custom_role.target_vulnerability_snapshot_role[0].id
  member = local.agentless_wif_principal
}

# =============================================================================
# Vulnerability Scanning: Multi-project mode - per-target-project snapshot role
# =============================================================================

resource "random_id" "target_vulnerability_role_suffix" {
  for_each    = var.enable_vulnerability_scanning ? toset(local.cross_target_ids) : toset([])
  byte_length = 4
}

resource "google_project_iam_custom_role" "target_vulnerability_snapshot_role" {
  for_each = var.enable_vulnerability_scanning ? toset(local.cross_target_ids) : toset([])

  project     = each.value
  role_id     = "${local.vulnerability_wif_target_role.id_prefix}_${local.role_suffix}_${random_id.target_vulnerability_role_suffix[each.value].hex}"
  title       = local.vulnerability_wif_target_role.title
  description = local.vulnerability_wif_target_role.description

  permissions = local.vulnerability_wif_target_role.permissions
}

resource "google_project_iam_member" "target_vulnerability_snapshot_permissions" {
  for_each = var.enable_vulnerability_scanning ? toset(local.cross_target_ids) : toset([])

  project = each.value
  role    = google_project_iam_custom_role.target_vulnerability_snapshot_role[each.value].id
  member  = local.agentless_wif_principal
}

# =============================================================================
# Vulnerability Scanning: Folder mode - org-level role bound at folder level
# =============================================================================

resource "random_id" "folder_vulnerability_role_suffix" {
  count       = var.enable_vulnerability_scanning && local.is_folder_registration ? 1 : 0
  byte_length = 4
}

resource "google_organization_iam_custom_role" "folder_vulnerability_snapshot_role" {
  count = var.enable_vulnerability_scanning && local.is_folder_registration ? 1 : 0

  org_id      = var.folder_org_id
  role_id     = "${local.vulnerability_wif_target_role.id_prefix}_${local.role_suffix}_${random_id.folder_vulnerability_role_suffix[0].hex}"
  title       = local.vulnerability_wif_target_role.title
  description = local.vulnerability_wif_target_role.description

  permissions = local.vulnerability_wif_target_role.permissions
}

resource "google_folder_iam_member" "folder_vulnerability_snapshot_permissions" {
  for_each = var.enable_vulnerability_scanning && local.is_folder_registration ? toset(var.folder_ids) : toset([])

  folder = "folders/${each.value}"
  role   = google_organization_iam_custom_role.folder_vulnerability_snapshot_role[0].id
  member = local.agentless_wif_principal
}
