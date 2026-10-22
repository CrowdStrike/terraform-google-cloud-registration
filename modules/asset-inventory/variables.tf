variable "wif_iam_principal" {
  type        = string
  description = "Google Cloud IAM Principal that identifies CrowdStrike resources"

  validation {
    condition     = can(regex("^(principal://|principalSet://|serviceAccount:)", var.wif_iam_principal))
    error_message = "IAM principal must be a valid principal, principalSet, or serviceAccount format."
  }
}


variable "project_ids" {
  type        = list(string)
  description = "List of Google Cloud project IDs for project-level registration"
  default     = []

  validation {
    condition = alltrue([
      for project_id in var.project_ids : length(project_id) >= 6 && length(project_id) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", project_id))
    ])
    error_message = "All project IDs must be 6-30 characters, start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and not end with a hyphen."
  }
}

variable "registration_type" {
  type        = string
  description = "The scope of the Google Cloud registration which can be one of the following values: organization, folder, project"
  validation {
    condition     = contains(["organization", "folder", "project"], var.registration_type)
    error_message = "Registration type must be one of: organization, folder, project."
  }
}

variable "organization_id" {
  type        = string
  description = "The Google Cloud organization being registered"
  default     = null

  validation {
    condition     = var.organization_id == null || can(regex("^[1-9][0-9]*$", var.organization_id))
    error_message = "Organization ID must be a numeric string without leading zeros when provided."
  }
}

variable "folder_ids" {
  type        = list(string)
  description = "List of Google Cloud folders being registered"
  default     = []

  validation {
    condition = alltrue([
      for folder_id in var.folder_ids : can(regex("^[1-9][0-9]*$", folder_id))
    ])
    error_message = "All folder IDs must be numeric strings without leading zeros."
  }
}


variable "google_iam_roles" {
  type        = list(string)
  description = "List of Google Cloud IAM roles that will be granted to the wif_iam_principal identity for asset inventory access at any registration scope"
  default = [
    "roles/aiplatform.viewer",
    "roles/alloydb.viewer",
    "roles/apigee.readOnlyAdmin",
    "roles/appengine.appViewer",
    "roles/artifactregistry.reader",
    "roles/backupdr.viewer",
    "roles/bigquery.metadataViewer",
    "roles/cloudasset.viewer",
    "roles/cloudfunctions.developer",
    "roles/cloudfunctions.viewer",
    "roles/cloudsql.viewer",
    "roles/cloudtasks.viewer",
    "roles/cloudtranslate.viewer",
    "roles/compute.viewer",
    "roles/container.viewer",
    "roles/dataplex.viewer",
    "roles/dialogflow.reader",
    "roles/eventarc.viewer",
    "roles/firebaseappcheck.viewer",
    "roles/firebaseauth.viewer",
    "roles/firebasedatabase.viewer",
    "roles/firebasehosting.viewer",
    "roles/firebasestorage.viewer",
    "roles/iam.securityReviewer",
    "roles/notebooks.viewer",
    "roles/recommender.iamViewer",
    "roles/recommender.iampolicychangeriskViewer",
    "roles/secretmanager.viewer",
    "roles/storage.bucketViewer"
  ]

  validation {
    condition = alltrue([
      for role in var.google_iam_roles : can(regex("^roles/", role))
    ])
    error_message = "All IAM roles must start with 'roles/'."
  }
}

variable "google_iam_roles_org_level" {
  type        = list(string)
  description = "IAM roles that are only meaningful at organization or folder scope. Bound for org/folder registration, skipped for project registration."
  default = [
    "roles/browser",
    "roles/essentialcontacts.viewer",
    "roles/securitycenter.adminViewer",
  ]

  validation {
    condition = alltrue([
      for role in var.google_iam_roles_org_level : can(regex("^roles/", role))
    ])
    error_message = "All IAM roles must start with 'roles/'."
  }
}

variable "google_iam_roles_project_level" {
  type        = list(string)
  description = "IAM roles that can only be applied at project scope (GCP limitation). Bound for project registration, skipped for org/folder registration."
  default     = []

  validation {
    condition = alltrue([
      for role in var.google_iam_roles_project_level : can(regex("^roles/", role))
    ])
    error_message = "All IAM roles must start with 'roles/'."
  }
}

variable "registration_id" {
  type        = string
  description = "Unique registration ID from CrowdStrike backend. Used as suffix for resources with soft-delete lifecycle (custom roles)."
  default     = ""

  validation {
    condition     = var.registration_id == "" || can(regex("^[a-z0-9-]+$", var.registration_id))
    error_message = "Registration ID must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "custom_role_permissions" {
  type        = list(string)
  description = "Permissions for the CrowdStrike custom IAM role. These are least-privilege permissions not covered by any predefined role."
  default     = []

  validation {
    condition = alltrue([
      for perm in var.custom_role_permissions : can(regex("^[a-zA-Z]", perm))
    ])
    error_message = "All permissions must start with a letter."
  }
}

variable "wif_project_id" {
  type        = string
  description = "Google Cloud Project ID where the CrowdStrike workload identity federation pool resources are deployed"

  validation {
    condition     = length(var.wif_project_id) >= 6 && length(var.wif_project_id) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.wif_project_id))
    error_message = "Project ID must be 6-30 characters, start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and not end with a hyphen."
  }
}

variable "manage_wif_project_apis" {
  type        = bool
  description = "Whether to enable the GCP APIs required for asset inventory scanning on wif_project_id. Set to false when attaching to a WIF pool created by an earlier registration: that registration already enabled these APIs, and this flow must not require any write access to the WIF/infra project."
  default     = true
}
