locals {
  # Custom IAM roles are supported for organization and project registration.
  # Folder registration requires creating the role at the org level, which needs
  # an additional organization ID input — this will be handled in a follow-up.
  create_custom_role = var.registration_type != "folder" && length(var.custom_role_permissions) > 0

  # Match agentless-scanning naming: {Prefix}_{role_suffix}_{random_hex}
  # role_id max 64 chars. "CspmAssetViewer" (15) + 2 separators + 8 hex = 25 overhead → 33-char reg_id fits (58 total)
  role_suffix = replace(substr(var.registration_id, 0, 33), "-", "_")

  cspm_custom_role = {
    id_prefix   = "CspmAssetViewer"
    title       = "CrowdStrike CSPM Asset Viewer"
    description = "Least-privilege permissions for CrowdStrike CSPM asset inventory scanning, replacing broader predefined roles"
    permissions = var.custom_role_permissions
  }
}

# =============================================================================
# Random suffix to avoid GCP 44-day soft-delete role ID collision
# =============================================================================

resource "random_id" "custom_role_org_suffix" {
  count       = local.create_custom_role && var.registration_type == "organization" ? 1 : 0
  byte_length = 4
}

resource "random_id" "custom_role_project_suffix" {
  for_each    = local.create_custom_role && var.registration_type == "project" ? toset(var.project_ids) : toset([])
  byte_length = 4
}

# =============================================================================
# Organization-level custom role
# =============================================================================

resource "google_organization_iam_custom_role" "cspm_asset_viewer" {
  count = local.create_custom_role && var.registration_type == "organization" ? 1 : 0

  org_id      = var.organization_id
  role_id     = "${local.cspm_custom_role.id_prefix}_${local.role_suffix}_${random_id.custom_role_org_suffix[0].hex}"
  title       = local.cspm_custom_role.title
  description = local.cspm_custom_role.description
  permissions = local.cspm_custom_role.permissions
}

resource "google_organization_iam_member" "cspm_custom_role" {
  count = local.create_custom_role && var.registration_type == "organization" ? 1 : 0

  org_id = var.organization_id
  role   = google_organization_iam_custom_role.cspm_asset_viewer[0].id
  member = var.wif_iam_principal
}

# =============================================================================
# Project-level custom role
# =============================================================================

resource "google_project_iam_custom_role" "cspm_asset_viewer" {
  for_each = local.create_custom_role && var.registration_type == "project" ? toset(var.project_ids) : toset([])

  project     = each.value
  role_id     = "${local.cspm_custom_role.id_prefix}_${local.role_suffix}_${random_id.custom_role_project_suffix[each.value].hex}"
  title       = local.cspm_custom_role.title
  description = local.cspm_custom_role.description
  permissions = local.cspm_custom_role.permissions
}

resource "google_project_iam_member" "cspm_custom_role" {
  for_each = local.create_custom_role && var.registration_type == "project" ? toset(var.project_ids) : toset([])

  project = each.value
  role    = google_project_iam_custom_role.cspm_asset_viewer[each.value].id
  member  = var.wif_iam_principal
}
