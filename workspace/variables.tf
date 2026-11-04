# The Google Cloud registration that has the Workspace

variable "gcp_registration_id" {
  type        = string
  description = "ID of the CrowdStrike Google Cloud registration that has the Google Workspace registration. Add the Google Workspace to it in the CrowdStrike console first."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.gcp_registration_id))
    error_message = "Google Cloud registration ID must be a lowercase UUID."
  }
}

# The CrowdStrike Workspace identity. Set exactly one

variable "workspace_role_arn" {
  type        = string
  description = "AWS Role ARN used by the CrowdStrike Workspace reader for authentication via WIF. Set this or workspace_service_account_unique_id, not both."
  default     = null

  validation {
    condition     = var.workspace_role_arn == null || can(regex("^arn:(aws|aws-us-gov|aws-cn):(iam|sts)::[0-9]{12}:(role|assumed-role)/.+", var.workspace_role_arn))
    error_message = "Workspace Role ARN must be a valid AWS IAM role ARN or STS assumed role ARN format."
  }
}

variable "workspace_service_account_unique_id" {
  type        = string
  description = "Unique ID of the CrowdStrike Workspace intermediate service account, for gcp-oidc clouds. Set this or workspace_role_arn, not both."
  default     = null

  validation {
    condition     = var.workspace_service_account_unique_id == null || can(regex("^[0-9]+$", var.workspace_service_account_unique_id))
    error_message = "Workspace service account unique ID must be numeric."
  }
}

# Google Cloud and Google Workspace

variable "wif_project_id" {
  type        = string
  description = "Google Cloud Project ID that holds the Workspace WIF pool and the Workspace service account. It is the WIF project of the Google Cloud registration."

  validation {
    condition     = length(var.wif_project_id) >= 6 && length(var.wif_project_id) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.wif_project_id))
    error_message = "Project ID must be 6-30 characters, start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and not end with a hyphen."
  }
}

variable "organization_id" {
  type        = string
  description = "ID of the GCP organization that belongs to the Google Workspace, with no organizations/ prefix."

  validation {
    condition     = can(regex("^[1-9][0-9]*$", var.organization_id))
    error_message = "Organization ID must be a numeric string without leading zeros."
  }
}

variable "customer_id" {
  type        = string
  description = "Google Workspace customer ID, for example C01abc23x, with no customers/ prefix. The plan fails when it does not belong to organization_id."

  validation {
    condition     = can(regex("^[Cc][A-Za-z0-9]+$", var.customer_id))
    error_message = "Workspace customer ID must start with C and contain only letters and numbers, with no customers/ prefix."
  }
}

variable "grant_organization_viewer" {
  type        = bool
  description = "Grant roles/resourcemanager.organizationViewer on organization_id to the Workspace service account. Set to false only when an organization admin makes this grant by hand."
  default     = true
}

# Naming
# The ternaries keep length() off a null: Terraform 1.5, the Infra Manager version, does not short-circuit ||.

variable "resource_prefix" {
  description = "Prefix to be added to the display names of the WIF pool and provider. Combined length of prefix + suffix must not exceed 13 characters."
  default     = null
  type        = string

  validation {
    condition     = var.resource_prefix == null ? true : (var.resource_prefix == "" || (can(regex("^[A-Za-z][A-Za-z0-9-]*$", var.resource_prefix)) && length(var.resource_prefix) <= 13))
    error_message = "Resource prefix must start with a letter, contain only letters, numbers, and hyphens, and be 13 characters or less."
  }
}

variable "resource_suffix" {
  type        = string
  description = "Suffix to be added to the display names of the WIF pool and provider. Combined length of prefix + suffix must not exceed 13 characters."
  default     = null

  validation {
    condition     = var.resource_suffix == null ? true : (var.resource_suffix == "" || (can(regex("^[A-Za-z0-9-]*[A-Za-z0-9]$", var.resource_suffix)) && length(var.resource_suffix) <= 13))
    error_message = "Resource suffix must end with a letter or number, contain only letters, numbers, and hyphens, and be 13 characters or less."
  }
}
