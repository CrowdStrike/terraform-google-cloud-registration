# =============================================================================
# Agentless Scanning Module
# =============================================================================
# Provisions GCP infrastructure for agentless scanning (DSPM, future: vulnerability scanning).
#
# Supports all registration modes:
#   Single project:     host_project_id only
#   Standalone cross:   host_project_id + project_ids (multi-project registration)
#   Folder cross:       folder_ids + org-level custom role (cross-only, enforced)
#   Org cross:          org_id + org-level custom role (cross-only, enforced)
#
# Org/Folder registrations are always cross-project (single host project, org-level IAM).
# Project registrations support both cross and per-project modes.
#
# Creates: Scanner SA, VPC, Subnet, optional NAT, GCS IAM, custom roles
# Does NOT create: Scanner VMs, Cloud SQL, BigQuery, Firestore
# =============================================================================

# =============================================================================
# Locals
# =============================================================================

locals {
  deployment_version = "1.2.0"

  # Guard for resources that reject uppercase
  effective_prefix = lower(var.resource_prefix)
  effective_suffix = lower(var.resource_suffix)

  # Mode detection
  is_org_registration     = var.registration_type == "organization"
  is_folder_registration  = var.registration_type == "folder"
  is_project_registration = var.registration_type == "project"

  # WIF Principal - Agentless scanning (shared pool, identity-source-dependent subject)
  # The ternary guarantees only the non-null variable is interpolated at runtime;
  # the fallback satisfies tflint's static null-in-string-template check.
  agentless_scanning_subject = (
    var.identity_source == "aws-sts"
    ? (var.agentless_scanning_role_arn != null ? var.agentless_scanning_role_arn : "")
    : (var.agentless_scanning_service_account_unique_id != null ? var.agentless_scanning_service_account_unique_id : "")
  )
  agentless_wif_principal = "principal://iam.googleapis.com/projects/${var.wif_project_number}/locations/global/workloadIdentityPools/${var.wif_pool_id}/subject/${local.agentless_scanning_subject}/${var.registration_id}"

  # Custom VPC mode detection
  is_custom_vpc = var.custom_vpc_configuration != null

  # Custom VPC subnet IAM pairs: flatten config into project/region pairs.
  # Keyed off the single scanner infra project (see custom_vpc_project_id), not
  # var.host_project_id, so single-project no-cross (host_project_id == null) works.
  # Empty when custom_vpc_project_id is null.
  custom_vpc_subnet_pairs = local.is_custom_vpc && local.custom_vpc_project_id != null ? {
    for region, subnet in var.custom_vpc_configuration.subnets :
    "${local.custom_vpc_project_id}/${region}" => { project = local.custom_vpc_project_id, region = region, subnetwork = subnet }
  } : {}

  # Registration ID truncated and sanitized for resource naming constraints:
  # - Custom role_id: max 64 chars. Longest role "AgentlessComputeMgr" (19) + 2 separators + 8 hex = 29 overhead → 33-char reg_id fits (62 total)
  #   Vuln roles use shorter id_prefixes: "VulnScannerDisk" (15), "VulnScanningOrch" (16) to stay within 64.
  # - SA account_id: max 30 chars. "csscan-" (7) + 8 hex + 13 (max prefix+suffix) = 28 → within limit
  # We use the tighter constraint (23) for resource names, and 33 for role IDs.
  role_suffix  = replace(substr(var.registration_id, 0, 33), "-", "_")
  reg_id_short = substr(var.registration_id, 0, 23)

  # Per-service DSPM permission gates. Each gates only its DSPM resources, so a flag
  # set to false never removes a permission vulnerability scanning relies on.
  create_gcs_permissions       = var.enable_dspm && var.dspm_gcs_access
  create_bigquery_permissions  = var.enable_dspm && var.dspm_bigquery_access
  create_dspm_disk_permissions = var.enable_dspm && var.dspm_disk_access
  create_cloudsql_permissions  = var.enable_dspm && var.dspm_cloudsql_access

  # Shared permission sets — single source of truth for permissions used by both DSPM and vulnerability roles.
  scanner_disk_permissions = [
    "compute.instances.attachDisk",
    "compute.instances.detachDisk",
    "compute.instances.get",
    "compute.disks.use",
    "compute.disks.useReadOnly",
    "compute.zoneOperations.get",
  ]

  snapshot_scanning_permissions = [
    "compute.disks.createSnapshot",
    "compute.snapshots.create",
    "compute.snapshots.setLabels",
    "compute.snapshots.useReadOnly",
    "compute.snapshots.delete",
  ]

  # Scanner GCS read role — reused across host project and cross-target roles at project/folder/org scope.
  scanner_gcs_role = {
    id_prefix   = "DSPMScannerGCSRead"
    title       = "DSPM Scanner GCS Read"
    description = "Minimal permissions for reading GCS objects in a given bucket"
    permissions = [
      "storage.objects.get",
      "storage.objects.list",
    ]
  }

  # Scanner BigQuery read role — reused across host project and cross-target roles at project/folder/org scope.
  # jobs.create is only exercised by external table scanning; granted now so enabling that needs no re-registration.
  scanner_bigquery_role = {
    id_prefix   = "DSPMScannerBQRead"
    title       = "DSPM Scanner BigQuery Read"
    description = "Minimal permissions for reading BigQuery dataset and table data"
    permissions = [
      "bigquery.datasets.get",
      "bigquery.tables.list",
      "bigquery.tables.get",
      "bigquery.tables.getData",
      "bigquery.jobs.create",
    ]
  }

  cloudsql_host_role = {
    id_prefix   = "DSPMCloudSQLHost"
    title       = "DSPM Cloud SQL Host"
    description = "Create, restore into and delete Cloud SQL scanning copies in the host project"
    permissions = [
      "cloudsql.instances.create",
      "cloudsql.instances.get",
      "cloudsql.instances.list",
      "cloudsql.instances.delete",
      "cloudsql.instances.restoreBackup",
      "cloudsql.users.list",
      "cloudsql.users.create",
      "cloudsql.users.update",
    ]
  }

  cloudsql_host_condition = {
    title = "cs-scanning-only-condition"
    expression = join(" || ", [
      "(resource.type == \"sqladmin.googleapis.com/Instance\" && resource.name.extract(\"/instances/cs-scanning-{id}\") != \"\")",
      "(resource.type != \"sqladmin.googleapis.com/Instance\")",
    ])
  }

  cloudsql_target_roles = {
    target = {
      id_prefix   = "DSPMCloudSQLTarget"
      title       = "DSPM Cloud SQL Target"
      description = "Read and clone Cloud SQL instances and read their backups for DSPM scanning"
      permissions = [
        "cloudsql.instances.get",
        "cloudsql.instances.clone",
        "cloudsql.instances.create",
        "cloudsql.backupRuns.list",
        "cloudsql.backupRuns.get",
      ]
      condition = null
    }
    clone = {
      id_prefix   = "DSPMCloudSQLClone"
      title       = "DSPM Cloud SQL Clone"
      description = "Update, back up and delete Cloud SQL scanning clones"
      permissions = [
        "cloudsql.instances.update",
        "cloudsql.instances.delete",
        "cloudsql.backupRuns.create",
        "cloudsql.backupRuns.delete",
      ]
      condition = {
        title      = "cs-scanning-only-condition"
        expression = "(resource.type == \"sqladmin.googleapis.com/Instance\" || resource.type == \"sqladmin.googleapis.com/BackupRun\") && resource.name.extract(\"/instances/cs-scanning-{id}\") != \"\""
      }
    }
  }

  # Vulnerability scanning infra role — reused across host project and cross-target roles at project/folder/org scope.
  vulnerability_wif_target_role = {
    id_prefix   = "VulnScanningOrch"
    title       = "Vulnerability Scanning Orchestrator"
    description = "Snapshot and clone disk permissions for cross-project vulnerability scanning"
    permissions = local.snapshot_scanning_permissions
  }

  # DSPM scanning infra role — reused across host project and cross-target roles at project/folder/org scope.
  dspm_gce_vm_wif_target_role = {
    id_prefix   = "DSPMScanningDisk"
    title       = "DSPM Scanning Disk"
    description = "Snapshot and clone disk permissions for cross-project DSPM scanning"
    permissions = local.snapshot_scanning_permissions
  }

  # IAM condition for snapshot scanning bindings — allows createSnapshot on any disk
  # but restricts snapshot mutations (create, delete, useReadOnly) to cs-scanning-* resources.
  # Shared by both vulnerability and DSPM scanning roles.
  snapshot_scanning_condition = {
    title       = "restrict-to-crowdstrike-scanning-snapshots"
    description = "Allow createSnapshot on any disk but restrict snapshot mutations to cs-scanning-* resources"
    expression = join(" || ", [
      "(resource.type == \"compute.googleapis.com/Disk\")",
      "(resource.type == \"compute.googleapis.com/Snapshot\" && resource.name.extract(\"cs-scanning-{id}\") != \"\")",
      "(resource.type != \"compute.googleapis.com/Disk\" && resource.type != \"compute.googleapis.com/Snapshot\")",
    ])
  }

  # -------------------------------------------------------------------------
  # Project lists
  # -------------------------------------------------------------------------

  # Projects that need full scanning infra (SA, VPC, NAT, custom roles, APIs)
  # - Cross-project (org/folder/multi-project): just the host project
  # - Per-project (project scope only): ALL project_ids (each gets full infra)
  host_project_ids = var.host_project_id != null ? [var.host_project_id] : var.project_ids

  # Single infra project that owns the scanner VPC/subnets (custom BYO VPC only).
  # Custom VPC requires exactly one infra project. Resolves to null when custom VPC
  # is unused or the infra project isn't exactly one, so local eval never crashes.
  custom_vpc_project_id = local.is_custom_vpc && length(local.host_project_ids) == 1 ? local.host_project_ids[0] : null

  # Projects that need scanning permissions only (cross mode targets for project registrations)
  # - Org/Folder: empty (org-level role handles all targets automatically)
  # - Project cross: project_ids minus host project
  # - No-cross: empty (each project has own infra with self-scan)
  cross_target_ids = var.host_project_id == null ? [] : (
    (local.is_org_registration || local.is_folder_registration) ? [] : [
      for project_id in var.project_ids : project_id if project_id != var.host_project_id
    ]
  )

  # Sorted regions for deterministic CIDR assignment (sets are unordered)
  sorted_regions = sort(tolist(var.regions))

  # -------------------------------------------------------------------------
  # Cross products for for_each iteration
  # -------------------------------------------------------------------------

  # APIs to enable per host project
  api_list = toset([
    "sts.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudasset.googleapis.com",
    "sqladmin.googleapis.com",
    "networkconnectivity.googleapis.com",
  ])

  project_api_pairs = { for pair in setproduct(local.host_project_ids, local.api_list) :
    "${pair[0]}/${pair[1]}" => { project = pair[0], api = pair[1] }
  }

  # Project × region pairs for subnet/router/NAT (managed VPC only)
  project_region_pairs = local.is_custom_vpc ? {} : { for pair in setproduct(local.host_project_ids, local.sorted_regions) :
    "${pair[0]}/${pair[1]}" => { project = pair[0], region = pair[1] }
  }

  # Same but only when NAT is enabled
  project_region_nat_pairs = local.is_custom_vpc || !var.deploy_cloud_nat ? {} : local.project_region_pairs

  # Empty with a custom VPC, because project_region_pairs is empty then
  cloudsql_scp_pairs        = local.create_cloudsql_permissions ? local.project_region_pairs : {}
  cloudsql_host_project_ids = local.create_cloudsql_permissions ? toset(local.host_project_ids) : toset([])

  cloudsql_target_project_role_pairs = local.create_cloudsql_permissions && local.is_project_registration ? {
    for pair in setproduct(concat(local.host_project_ids, local.cross_target_ids), keys(local.cloudsql_target_roles)) :
    "${pair[0]}/${pair[1]}" => { project = pair[0], role_key = pair[1] }
  } : {}

  cloudsql_target_org_role_keys = local.create_cloudsql_permissions && !local.is_project_registration ? toset(keys(local.cloudsql_target_roles)) : toset([])

  cloudsql_target_folder_role_pairs = local.create_cloudsql_permissions && local.is_folder_registration ? {
    for pair in setproduct(var.folder_ids, keys(local.cloudsql_target_roles)) :
    "${pair[0]}/${pair[1]}" => { folder = pair[0], role_key = pair[1] }
  } : {}

  # Viewer roles supported at all levels (project, folder, org)
  viewer_roles_base = [
    "roles/iam.securityReviewer",
    "roles/compute.viewer",
    "roles/monitoring.viewer",
    "roles/logging.privateLogViewer",
    "roles/cloudasset.viewer",
    "roles/secretmanager.viewer",
    "roles/browser",
  ]

  # Each of these is the backend half of a per-service grant: insightsCollectorService carries
  # storage.buckets.get, metadataViewer the dataset and table location reads.
  viewer_roles = toset(concat(
    local.viewer_roles_base,
    local.create_gcs_permissions ? ["roles/storage.insightsCollectorService"] : [],
    local.create_bigquery_permissions ? ["roles/bigquery.metadataViewer"] : [],
  ))

  # Viewer roles only supported at project level (GCP limitation)
  viewer_roles_project_only = toset([
    "roles/iam.roleViewer",
  ])
}

# =============================================================================
# Input Validation
# =============================================================================

resource "terraform_data" "agentless_validation" {
  lifecycle {
    precondition {
      condition     = var.enable_dspm || var.enable_vulnerability_scanning
      error_message = "At least one of enable_dspm or enable_vulnerability_scanning must be true."
    }
    precondition {
      condition = (
        (var.identity_source == "aws-sts" && var.agentless_scanning_role_arn != null) ||
        (var.identity_source == "gcp-oidc" && var.agentless_scanning_service_account_unique_id != null)
      )
      error_message = "When identity_source is aws-sts, agentless_scanning_role_arn is required. When identity_source is gcp-oidc, agentless_scanning_service_account_unique_id is required."
    }
    precondition {
      condition     = var.falcon_client_id != null && var.falcon_client_secret != null
      error_message = "falcon_client_id and falcon_client_secret are required when enable_dspm or enable_vulnerability_scanning is true."
    }
    precondition {
      condition     = var.registration_type == "project" || var.host_project_id != null
      error_message = "Organization and folder registrations require cross-project mode (agentless_scanning_settings.host_project_id must be set)."
    }
    precondition {
      condition = var.registration_type != "project" || (
        var.host_project_id == null ? true : contains(var.project_ids, var.host_project_id)
      )
      error_message = "agentless_scanning_settings.host_project_id must be one of the registered project_ids for project registration."
    }
    precondition {
      condition     = var.registration_type != "folder" || var.folder_org_id != null
      error_message = "agentless_scanning_settings.org_id is required for folder registration when enable_dspm = true."
    }
    precondition {
      condition     = var.custom_vpc_configuration == null || length(local.host_project_ids) == 1
      error_message = "agentless_scanning_settings.custom_vpc_configuration requires exactly one scanner infra project: use cross-project mode (set host_project_id) or register a single project. Multi-project no-cross has one infra project per project_id and cannot share a single VPC."
    }
  }
}

# =============================================================================
# Host Project Scope Validation
# =============================================================================
# For org/folder registrations, validates that the host project (where scanning
# infra is deployed) actually belongs to the registered org or folder.
# Skipped for project registrations (the agentless_validation precondition handles that).

data "google_project_ancestry" "host_project_scope_check" {
  count   = local.is_project_registration ? 0 : 1
  project = var.host_project_id

  lifecycle {
    postcondition {
      condition = local.is_org_registration ? contains(
        [for a in self.ancestors : a.id if a.type == "organization"],
        var.organization_id
        ) : length(setintersection(
          toset(var.folder_ids),
          toset([for a in self.ancestors : a.id if a.type == "folder"])
      )) > 0
      error_message = "Host project '${var.host_project_id}' is not within the registered ${local.is_org_registration ? "organization '${var.organization_id}'" : "folder(s)"}."
    }
  }
}

# =============================================================================
# API Services (per host project)
# =============================================================================

resource "google_project_service" "serviceusage" {
  for_each = toset(local.host_project_ids)

  project = each.value
  service = "serviceusage.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false

  depends_on = [data.google_project_ancestry.host_project_scope_check]
}

resource "google_project_service" "required_apis" {
  for_each = local.project_api_pairs

  project = each.value.project
  service = each.value.api

  disable_dependent_services = false
  disable_on_destroy         = false

  depends_on = [google_project_service.serviceusage]
}

# =============================================================================
# DSPM Cloud SQL Scanning - Service Connection Policy
# =============================================================================

resource "google_network_connectivity_service_connection_policy" "cloudsql" {
  for_each = local.cloudsql_scp_pairs

  project       = each.value.project
  name          = "${local.effective_prefix}agentless-cloudsql-${each.value.region}${local.effective_suffix}"
  location      = each.value.region
  service_class = "google-cloud-sql"
  network       = google_compute_network.agentless_vpc[each.value.project].id
  description   = "PSC auto-connections for CrowdStrike DSPM Cloud SQL scanning copies"

  psc_config {
    subnetworks = [google_compute_subnetwork.agentless_subnet[each.key].id]
  }

  depends_on = [google_project_service.required_apis]
}

# =============================================================================
# DSPM Cloud SQL Scanning - Host Role (per host project)
# =============================================================================

resource "random_id" "cloudsql_host_role_suffix" {
  for_each    = local.cloudsql_host_project_ids
  byte_length = 4
}

resource "google_project_iam_custom_role" "cloudsql_host_role" {
  for_each = local.cloudsql_host_project_ids

  project     = each.value
  role_id     = "${local.cloudsql_host_role.id_prefix}_${local.role_suffix}_${random_id.cloudsql_host_role_suffix[each.value].hex}"
  title       = local.cloudsql_host_role.title
  description = local.cloudsql_host_role.description

  permissions = local.cloudsql_host_role.permissions

  depends_on = [google_project_service.required_apis]
}

resource "google_project_iam_member" "cloudsql_host_permissions" {
  for_each = local.cloudsql_host_project_ids

  project = each.value
  role    = google_project_iam_custom_role.cloudsql_host_role[each.value].id
  member  = local.agentless_wif_principal

  condition {
    title      = local.cloudsql_host_condition.title
    expression = local.cloudsql_host_condition.expression
  }
}

# =============================================================================
# DSPM Cloud SQL Scanning - Target Roles: project registration (host + cross targets)
# =============================================================================

resource "random_id" "cloudsql_target_role_suffix" {
  for_each    = local.cloudsql_target_project_role_pairs
  byte_length = 4
}

resource "google_project_iam_custom_role" "cloudsql_target_role" {
  for_each = local.cloudsql_target_project_role_pairs

  project     = each.value.project
  role_id     = "${local.cloudsql_target_roles[each.value.role_key].id_prefix}_${local.role_suffix}_${random_id.cloudsql_target_role_suffix[each.key].hex}"
  title       = local.cloudsql_target_roles[each.value.role_key].title
  description = local.cloudsql_target_roles[each.value.role_key].description

  permissions = local.cloudsql_target_roles[each.value.role_key].permissions

  depends_on = [google_project_service.required_apis]
}

resource "google_project_iam_member" "cloudsql_target_permissions" {
  for_each = local.cloudsql_target_project_role_pairs

  project = each.value.project
  role    = google_project_iam_custom_role.cloudsql_target_role[each.key].id
  member  = local.agentless_wif_principal

  dynamic "condition" {
    for_each = local.cloudsql_target_roles[each.value.role_key].condition[*]
    content {
      title      = condition.value.title
      expression = condition.value.expression
    }
  }
}

# =============================================================================
# DSPM Cloud SQL Scanning - Target Roles: org / folder registration
# =============================================================================

resource "random_id" "cloudsql_target_org_role_suffix" {
  for_each    = local.cloudsql_target_org_role_keys
  byte_length = 4
}

resource "google_organization_iam_custom_role" "cloudsql_target_role" {
  for_each = local.cloudsql_target_org_role_keys

  org_id      = local.is_org_registration ? var.organization_id : var.folder_org_id
  role_id     = "${local.cloudsql_target_roles[each.value].id_prefix}_${local.role_suffix}_${random_id.cloudsql_target_org_role_suffix[each.value].hex}"
  title       = local.cloudsql_target_roles[each.value].title
  description = local.cloudsql_target_roles[each.value].description

  permissions = local.cloudsql_target_roles[each.value].permissions
}

resource "google_organization_iam_member" "cloudsql_target_permissions" {
  for_each = local.is_org_registration ? local.cloudsql_target_org_role_keys : toset([])

  org_id = var.organization_id
  role   = google_organization_iam_custom_role.cloudsql_target_role[each.value].id
  member = local.agentless_wif_principal

  dynamic "condition" {
    for_each = local.cloudsql_target_roles[each.value].condition[*]
    content {
      title      = condition.value.title
      expression = condition.value.expression
    }
  }
}

resource "google_folder_iam_member" "cloudsql_target_permissions" {
  for_each = local.cloudsql_target_folder_role_pairs

  folder = "folders/${each.value.folder}"
  role   = google_organization_iam_custom_role.cloudsql_target_role[each.value.role_key].id
  member = local.agentless_wif_principal

  dynamic "condition" {
    for_each = local.cloudsql_target_roles[each.value.role_key].condition[*]
    content {
      title      = condition.value.title
      expression = condition.value.expression
    }
  }
}
