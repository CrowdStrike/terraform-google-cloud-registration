# =============================================================================
# Agentless Scanning Module - Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Common (passed from root module)
# -----------------------------------------------------------------------------

variable "registration_type" {
  type        = string
  description = "Type of registration: organization, folder, or project"

  validation {
    condition     = contains(["organization", "folder", "project"], var.registration_type)
    error_message = "Registration type must be one of: organization, folder, project."
  }
}

variable "registration_id" {
  type        = string
  description = "Unique registration ID from CrowdStrike backend. Used as suffix for resources with soft-delete lifecycle (SA, custom roles)."

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.registration_id))
    error_message = "Registration ID must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "host_project_id" {
  type        = string
  description = "Google Cloud Project ID hosting the agentless scanning infrastructure (the host project). Set only in cross-project mode (org/folder/multi-project); null for per-project (no-cross) registrations where each project self-hosts."
  default     = null

  validation {
    condition     = var.host_project_id == null ? true : (length(var.host_project_id) >= 6 && length(var.host_project_id) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.host_project_id)))
    error_message = "Host project ID must be 6-30 characters, start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and not end with a hyphen."
  }
}

variable "project_ids" {
  type        = list(string)
  description = "List of registered project IDs (full registration scope). Used for viewer role bindings and cross/no-cross target derivation."
  default     = []

  validation {
    condition = alltrue([
      for project_id in var.project_ids : length(project_id) >= 6 && length(project_id) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", project_id))
    ])
    error_message = "All project IDs must be 6-30 characters, start with lowercase letter, contain only lowercase letters/numbers/hyphens, and not end with hyphen."
  }
}

variable "organization_id" {
  type        = string
  description = "GCP Organization ID for organization-level registration"
  default     = null

  validation {
    condition     = var.organization_id == null || can(regex("^[1-9][0-9]*$", var.organization_id))
    error_message = "Organization ID must be a numeric string without leading zeros when provided."
  }
}

variable "folder_org_id" {
  type        = string
  description = "Parent GCP Organization ID of the registered folder(s). Required for folder registration to host the org-level scanner custom role bound at folder scope."
  default     = null

  validation {
    condition     = var.folder_org_id == null || can(regex("^[1-9][0-9]*$", var.folder_org_id))
    error_message = "Folder org ID must be a numeric string without leading zeros when provided."
  }
}

variable "folder_ids" {
  type        = list(string)
  description = "List of Google Cloud folder IDs for folder-level registration"
  default     = []

  validation {
    condition = alltrue([
      for folder_id in var.folder_ids : can(regex("^[1-9][0-9]*$", folder_id))
    ])
    error_message = "All folder IDs must be numeric strings without leading zeros."
  }
}

variable "labels" {
  type        = map(string)
  description = "Map of labels to be applied to all resources that support them"
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.labels : can(regex("^[a-z][a-z0-9_-]{0,62}$", key))
    ])
    error_message = "Label keys must start with lowercase letter, contain only lowercase letters, numbers, hyphens, and underscores, and be 1-63 characters long."
  }

  validation {
    condition = alltrue([
      for key, value in var.labels : can(regex("^[a-z0-9_-]{0,63}$", value))
    ])
    error_message = "Label values must contain only lowercase letters, numbers, hyphens, and underscores, and be 0-63 characters long."
  }

  validation {
    condition     = length(var.labels) <= 64
    error_message = "Maximum of 64 labels allowed per resource."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix to be added to created resource names"
  default     = ""
}

variable "resource_suffix" {
  type        = string
  description = "Suffix to be added to created resource names"
  default     = ""
}

# -----------------------------------------------------------------------------
# WIF (from workload-identity module outputs)
# -----------------------------------------------------------------------------

variable "wif_project_number" {
  type        = string
  description = "GCP Project Number for the WIF project (used in principal construction)"
  validation {
    condition     = can(regex("^[0-9]+$", var.wif_project_number))
    error_message = "WIF project number must be a numeric string."
  }
}

variable "wif_pool_id" {
  type        = string
  description = "Workload Identity Pool ID from the shared CSPM WIF pool"
}

variable "agentless_scanning_role_arn" {
  type        = string
  description = "AWS Role ARN used by CrowdStrike agentless scanning for authentication via WIF"

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):(iam|sts)::[0-9]{12}:(role|assumed-role)/.+", var.agentless_scanning_role_arn))
    error_message = "Agentless scanning Role ARN must be a valid AWS IAM role ARN or STS assumed role ARN format."
  }
}

# -----------------------------------------------------------------------------
# Falcon Credentials (stored in Secret Manager per host project)
# -----------------------------------------------------------------------------

variable "falcon_client_id" {
  type        = string
  sensitive   = true
  description = "Falcon API client ID for scanner authentication"
  validation {
    condition     = length(var.falcon_client_id) == 32 && can(regex("^[a-fA-F0-9]+$", var.falcon_client_id))
    error_message = "falcon_client_id must be a 32-character hexadecimal string. Please use the Falcon console to generate a new API key/secret pair with appropriate scopes."
  }
}

variable "falcon_client_secret" {
  type        = string
  sensitive   = true
  description = "Falcon API client secret for scanner authentication"
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "regions" {
  type        = set(string)
  description = "GCP regions to deploy scanner infrastructure (VPC, subnets, NAT)."
  default     = []

  validation {
    condition     = length(var.regions) > 0
    error_message = "At least one region must be specified."
  }

  validation {
    condition     = alltrue([for r in var.regions : can(regex("^[a-z]+-[a-z]+[0-9]+$", r))])
    error_message = "Each region must be a valid GCP region format (e.g., 'us-east1', 'europe-west4', 'asia-southeast1')."
  }
}

variable "deploy_cloud_nat" {
  type        = bool
  description = "Deploy Cloud NAT for scanner VMs. true = private IPs + NAT, false = public IPs."
  default     = true
}

variable "custom_vpc_configuration" {
  type = object({
    vpc_name = string
    subnets  = map(string)
  })
  description = "Custom VPC configuration for the host project. When set, uses the provided VPC/subnets instead of creating a managed VPC. vpc_name = VPC name, subnets = {region = subnet_name}."
  default     = null
}
