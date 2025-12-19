# =============================================================================
# Variables for CrowdStrike GCP CSPM Generic Registration
# =============================================================================
# These variables can be provided via GCP Infrastructure Manager URL parameters
# or deployment configuration.
# =============================================================================

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "falcon_client_id" {
  type        = string
  sensitive   = true
  description = "Falcon API client ID."
  validation {
    condition     = length(var.falcon_client_id) == 32 && can(regex("^[a-fA-F0-9]+$", var.falcon_client_id))
    error_message = "falcon_client_id must be a 32-character hexadecimal string. Please use the Falcon console to generate a new API key/secret pair with appropriate scopes."
  }
}

variable "falcon_client_secret" {
  type        = string
  sensitive   = true
  description = "Falcon API client secret."
  validation {
    condition     = length(var.falcon_client_secret) == 40 && can(regex("^[a-zA-Z0-9]+$", var.falcon_client_secret))
    error_message = "falcon_client_secret must be a 40-character hexadecimal string. Please use the Falcon console to generate a new API key/secret pair with appropriate scopes."
  }
}

variable "wif_project_id" {
  type        = string
  description = "Google Cloud Project ID where the CrowdStrike workload identity federation pool resources are deployed. Defaults to infra_project_id if not specified"
  default     = null

  validation {
    condition     = var.wif_project_id == null || (length(var.wif_project_id) >= 6 && length(var.wif_project_id) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.wif_project_id)))
    error_message = "Project ID must be 6-30 characters, start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and not end with a hyphen."
  }
}

variable "infra_project_id" {
  type        = string
  description = "GCP Project ID where CrowdStrike infrastructure will be created (WIF pools, Pub/Sub topics, etc.)"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.infra_project_id))
    error_message = "Project ID must be 6-30 characters, start with lowercase letter, contain only lowercase letters/numbers/hyphens, and not end with hyphen."
  }
}

variable "registration_name" {
  type        = string
  description = "Name for the CrowdStrike GCP registration"
}

variable "registration_type" {
  type        = string
  description = "Type of registration: organization, folder, or project"
  validation {
    condition     = contains(["organization", "folder", "project"], var.registration_type)
    error_message = "Registration type must be one of: organization, folder, project."
  }
}

variable "deployment_method" {
  type        = string
  description = "Deployment method for the CrowdStrike GCP registration"
  default     = "terraform-native"

  validation {
    condition     = contains(["terraform-native", "infrastructure-manager"], var.deployment_method)
    error_message = "Deployment method must be one of: terraform-native, infrastructure-manager."
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

variable "project_ids" {
  type        = list(string)
  description = "List of GCP Project IDs to register with CrowdStrike CSPM"
  default     = []

  validation {
    condition = alltrue([
      for project_id in var.project_ids : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", project_id))
    ])
    error_message = "All project IDs must be 6-30 characters, start with lowercase letter, contain only lowercase letters/numbers/hyphens, and not end with hyphen."
  }
}

variable "role_arn" {
  type        = string
  description = "AWS IAM Role ARN for CrowdStrike identity federation"

  validation {
    condition     = can(regex("^arn:aws:sts::[0-9]{12}:assumed-role/.+", var.role_arn))
    error_message = "Role ARN must be a valid AWS STS assumed role ARN format."
  }
}

# =============================================================================
# OPTIONAL FEATURES
# =============================================================================

variable "enable_realtime_visibility" {
  type        = bool
  description = "Enable Real Time Visibility & Detection features (requires log ingestion setup)"
  default     = false
}

# =============================================================================
# RESOURCE NAMING & ORGANIZATION
# =============================================================================

variable "resource_prefix" {
  description = "Prefix to be added to all created resource names for identification"
  default     = null
  type        = string

  validation {
    condition     = var.resource_prefix == null || var.resource_prefix == "" || (can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]*$", var.resource_prefix)) && length(var.resource_prefix) <= 13)
    error_message = "Resource prefix must start with alphanumeric character and contain only letters, numbers, underscores, hyphens, and periods, and be 13 characters or less."
  }
}

variable "resource_suffix" {
  type        = string
  description = "Suffix to be added to all created resource names for identification"
  default     = null

  validation {
    condition     = var.resource_suffix == null || var.resource_suffix == "" || (can(regex("^[A-Za-z0-9_.-]*$", var.resource_suffix)) && length(var.resource_suffix) <= 13)
    error_message = "Resource suffix must contain only letters, numbers, underscores, hyphens, and periods, and be 13 characters or less."
  }
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to all created resources"
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.labels : can(regex("^[a-z][a-z0-9_-]{0,62}$", key))
    ])
    error_message = "Label keys must start with lowercase letter, contain only lowercase letters/numbers/hyphens/underscores, and be 1-63 characters."
  }

  validation {
    condition = alltrue([
      for key, value in var.labels : can(regex("^[a-z0-9_-]{0,63}$", value))
    ])
    error_message = "Label values must contain only lowercase letters/numbers/hyphens/underscores, and be 0-63 characters."
  }

  validation {
    condition     = length(var.labels) <= 64
    error_message = "Maximum of 64 custom labels allowed."
  }
}

# =============================================================================
# LOG INGESTION SETTINGS
# =============================================================================

variable "log_ingestion_settings" {
  description = "Configuration settings for log ingestion. Controls Pub/Sub topic and subscription settings, audit log types, schema validation, and allows using existing resources."
  type = object({
    message_retention_duration       = optional(string, "604800s")
    ack_deadline_seconds             = optional(number, 600)
    topic_message_retention_duration = optional(string, "604800s")
    audit_log_types                  = optional(list(string), ["activity", "system_event", "policy"])
    topic_storage_regions            = optional(list(string), [])
    enable_schema_validation         = optional(bool, false)
    schema_type                      = optional(string, "AVRO")
    schema_definition                = optional(string)
    existing_topic_name              = optional(string)
    existing_subscription_name       = optional(string)
    exclusion_filters                = optional(list(string), [])
  })
  default = {}
}
