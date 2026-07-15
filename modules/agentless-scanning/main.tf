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
  deployment_version = "1.0.0"

  # Mode detection
  is_org_registration     = var.registration_type == "organization"
  is_folder_registration  = var.registration_type == "folder"
  is_project_registration = var.registration_type == "project"

  # WIF Principal - Agentless scanning (shared pool, identity-source-dependent subject)
  agentless_wif_principal = (
    var.identity_source == "aws-sts"
    ? "principal://iam.googleapis.com/projects/${var.wif_project_number}/locations/global/workloadIdentityPools/${var.wif_pool_id}/subject/${var.agentless_scanning_role_arn}/${var.registration_id}"
    : "principal://iam.googleapis.com/projects/${var.wif_project_number}/locations/global/workloadIdentityPools/${var.wif_pool_id}/subject/${var.agentless_scanning_service_account_unique_id}"
  )

  # Custom VPC mode detection
  is_custom_vpc = var.custom_vpc_configuration != null

  # Custom VPC subnet IAM pairs: flatten config into project/region pairs.
  # Keyed off the single scanner infra project (see custom_vpc_project_id), not
  # var.host_project_id, so single-project no-cross (host_project_id == null) works.
  custom_vpc_subnet_pairs = local.is_custom_vpc ? {
    for region, subnet in var.custom_vpc_configuration.subnets :
    "${local.custom_vpc_project_id}/${region}" => { project = local.custom_vpc_project_id, region = region, subnetwork = subnet }
  } : {}

  # Registration ID truncated and sanitized for resource naming constraints:
  # - Custom role_id: max 64 chars. Longest role "AgentlessComputeMgr" (19) + 2 separators + 8 hex = 29 overhead → 33-char reg_id fits (62 total)
  # - SA account_id: max 30 chars. "csscan-" (7) + 8 hex + 13 (max prefix+suffix) = 28 → within limit
  # We use the tighter constraint (23) for resource names, and 33 for role IDs.
  role_suffix  = replace(substr(var.registration_id, 0, 33), "-", "_")
  reg_id_short = substr(var.registration_id, 0, 23)

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

  # -------------------------------------------------------------------------
  # Project lists
  # -------------------------------------------------------------------------

  # Projects that need full scanning infra (SA, VPC, NAT, custom roles, APIs)
  # - Cross-project (org/folder/multi-project): just the host project
  # - Per-project (project scope only): ALL project_ids (each gets full infra)
  host_project_ids = var.host_project_id != null ? [var.host_project_id] : var.project_ids

  # The single project that owns the scanner VPC/subnets, used by custom (BYO) VPC.
  # Custom VPC requires exactly one infra project: cross => the host project;
  # single-project no-cross => that one project. one() errors if there is >1 infra
  # project (multi-project no-cross), which custom VPC can't support — a cryptic
  # last-line backstop. The root module's friendly precondition on
  # crowdstrike_cloud_google_registration.main catches this first in normal use.
  custom_vpc_project_id = one(local.host_project_ids)

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
    "secretmanager.googleapis.com",
    "cloudasset.googleapis.com",
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

  # Viewer roles supported at all levels (project, folder, org)
  viewer_roles = toset([
    "roles/iam.securityReviewer",
    "roles/compute.viewer",
    "roles/monitoring.viewer",
    "roles/logging.privateLogViewer",
    "roles/cloudasset.viewer",
    "roles/storage.insightsCollectorService",
    "roles/secretmanager.viewer",
    "roles/browser",
  ])

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
      condition = (
        (var.identity_source == "aws-sts" && var.agentless_scanning_role_arn != null) ||
        (var.identity_source == "gcp-oidc" && var.agentless_scanning_service_account_unique_id != null)
      )
      error_message = "When identity_source is aws-sts, agentless_scanning_role_arn is required. When identity_source is gcp-oidc, agentless_scanning_service_account_unique_id is required."
    }
    precondition {
      condition     = var.falcon_client_id != null && var.falcon_client_secret != null
      error_message = "falcon_client_id and falcon_client_secret are required when enable_dspm = true."
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
