variable "wif_project_id" {
  type        = string
  description = "Google Cloud Project ID that hosts the Workspace Workload Identity Federation pool and the Workspace service account"

  validation {
    condition     = length(var.wif_project_id) >= 6 && length(var.wif_project_id) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.wif_project_id))
    error_message = "Project ID must be 6-30 characters, start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and not end with a hyphen."
  }
}

variable "service_account_id" {
  type        = string
  description = "Account ID of the Workspace service account. CrowdStrike computes it from the Workspace registration ID and shows the email before the apply, so pass the value unchanged"

  validation {
    condition     = can(regex("^[a-z][-a-z0-9]{4,28}[a-z0-9]$", var.service_account_id))
    error_message = "Service account ID must be 6-30 characters, start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and not end with a hyphen."
  }
}

variable "workspace_wif_principal" {
  type        = string
  description = "Subject-scoped principal:// URI of the CrowdStrike Workspace identity for this registration. Use the wif_iam_principal output of the workload-identity module"

  validation {
    condition     = can(regex("^principal://iam\\.googleapis\\.com/projects/[0-9]+/locations/global/workloadIdentityPools/[a-z0-9-]+/subject/.+$", var.workspace_wif_principal))
    error_message = "Workspace WIF principal must be a subject-scoped principal:// URI. A principalSet:// URI admits every identity on the pool."
  }
}

variable "organization_id" {
  type        = string
  description = "GCP organization ID linked to the Workspace, with no organizations/ prefix"

  validation {
    condition     = can(regex("^[1-9][0-9]*$", var.organization_id))
    error_message = "Organization ID must be a numeric string without leading zeros, with no organizations/ prefix."
  }
}

variable "grant_organization_viewer" {
  type        = bool
  description = "Grant roles/resourcemanager.organizationViewer on the organization to the Workspace service account. Set to false only when an organization admin makes the grant by hand"
  default     = true
}
