# =============================================================================
# IAM - Service Accounts, Custom Roles, Viewer Roles
# =============================================================================

# =============================================================================
# Scanner Service Account (per host project)
# =============================================================================

# Protects SA and custom roles against soft-delete collisions
resource "random_id" "infra_suffix" {
  for_each    = toset(local.host_project_ids)
  byte_length = 4
}

resource "google_service_account" "scanner_sa" {
  for_each = toset(local.host_project_ids)

  project      = each.value
  account_id   = "${var.resource_prefix}csscan-${random_id.infra_suffix[each.value].hex}${var.resource_suffix}"
  display_name = "Agentless Scanner SA"
  description  = "Runs on scanner VM, has GCS read permissions"

  depends_on = [google_project_service.required_apis]
}

# =============================================================================
# GCS IAM - Scanner SA Custom Role (per host project)
# =============================================================================

# Protects scanner_gcs_role against 44-day soft-delete collision
resource "random_id" "gcs_role_suffix" {
  for_each    = toset(local.host_project_ids)
  byte_length = 4
}

resource "google_project_iam_custom_role" "scanner_gcs_role" {
  for_each = toset(local.host_project_ids)

  project     = each.value
  role_id     = "DSPMScannerGCSRead_${local.role_suffix}_${random_id.gcs_role_suffix[each.value].hex}"
  title       = local.scanner_gcs_role.title
  description = local.scanner_gcs_role.description

  permissions = local.scanner_gcs_role.permissions

  depends_on = [google_project_service.required_apis]
}

resource "google_project_iam_member" "scanner_gcs_permissions" {
  for_each = toset(local.host_project_ids)

  project = each.value
  role    = google_project_iam_custom_role.scanner_gcs_role[each.value].id
  member  = "serviceAccount:${google_service_account.scanner_sa[each.value].email}"
}

# =============================================================================
# WIF Principal - Compute Manager Custom Role (per host project)
# =============================================================================

resource "google_project_iam_custom_role" "wif_compute_role" {
  for_each = toset(local.host_project_ids)

  project     = each.value
  role_id     = "AgentlessComputeMgr_${local.role_suffix}_${random_id.infra_suffix[each.value].hex}"
  title       = "Agentless Scanning Compute Manager"
  description = "Minimal compute permissions for scanner VM lifecycle"

  permissions = [
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    "compute.instances.setLabels",
    "compute.instances.start",
    "compute.disks.create",
    "compute.disks.delete",
    "compute.disks.use",
    "compute.images.useReadOnly",
    "compute.zoneOperations.get",
    "compute.instances.getSerialPortOutput",
  ]

  depends_on = [google_project_service.required_apis]
}

# IAM Condition restricts mutations to CrowdStrike scanner resources only
resource "google_project_iam_member" "wif_compute" {
  for_each = toset(local.host_project_ids)

  project = each.value
  role    = google_project_iam_custom_role.wif_compute_role[each.value].id
  member  = local.agentless_wif_principal

  condition {
    title       = "restrict-to-crowdstrike-scanner-resources"
    description = "Limit mutations to CrowdStrike agentless scanner resources only"
    expression = join(" || ", [
      "(resource.type == \"compute.googleapis.com/Instance\" && resource.name.extract(\"cs-scanning-{id}\") != \"\")",
      "(resource.type == \"compute.googleapis.com/Disk\" && resource.name.extract(\"cs-scanning-{id}\") != \"\")",
      "(resource.type != \"compute.googleapis.com/Instance\" && resource.type != \"compute.googleapis.com/Disk\")",
    ])
  }
}

# WIF principal can use scanner SA (attach to VMs)
resource "google_service_account_iam_member" "wif_can_use_scanner_sa" {
  for_each = toset(local.host_project_ids)

  service_account_id = google_service_account.scanner_sa[each.value].id
  role               = "roles/iam.serviceAccountUser"
  member             = local.agentless_wif_principal
}

# =============================================================================
# WIF Principal - Viewer Roles (Read-Only Ops & Debug)
# =============================================================================

# Project registration: viewer roles on ALL registered projects
resource "google_project_iam_member" "wif_viewer_roles" {
  for_each = local.is_project_registration ? { for pair in setproduct(var.project_ids, tolist(setunion(local.viewer_roles, local.viewer_roles_project_only))) :
    "${pair[0]}/${pair[1]}" => { project = pair[0], role = pair[1] }
  } : {}

  project = each.value.project
  role    = each.value.role
  member  = local.agentless_wif_principal
}

# Folder/Org mode: project-only roles bound on each host project
resource "google_project_iam_member" "wif_viewer_roles_project_only" {
  for_each = !local.is_project_registration ? {
    for pair in setproduct(local.host_project_ids, tolist(local.viewer_roles_project_only)) :
    "${pair[0]}/${pair[1]}" => { project = pair[0], role = pair[1] }
  } : {}

  project = each.value.project
  role    = each.value.role
  member  = local.agentless_wif_principal
}

# Folder mode: viewer roles at folder level (inherits to all child projects)
resource "google_folder_iam_member" "wif_viewer_roles" {
  for_each = local.is_folder_registration ? { for pair in setproduct(var.folder_ids, local.viewer_roles) :
    "${pair[0]}/${pair[1]}" => { folder = pair[0], role = pair[1] }
  } : {}

  folder = "folders/${each.value.folder}"
  role   = each.value.role
  member = local.agentless_wif_principal
}

# Org mode: viewer roles at org level (inherits to all projects)
resource "google_organization_iam_member" "wif_viewer_roles" {
  for_each = local.is_org_registration ? local.viewer_roles : toset([])

  org_id = var.organization_id
  role   = each.value
  member = local.agentless_wif_principal
}
