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

variable "registration_type" {
  type        = string
  description = "Type of registration: organization, folder, or project"
  validation {
    condition     = contains(["organization", "folder", "project"], var.registration_type)
    error_message = "Registration type must be one of: organization, folder, project."
  }
}

variable "organization_id" {
  type        = string
  description = "GCP Organization ID for organization-level registration"
  default     = null

  validation {
    condition     = var.organization_id == null || can(regex("^[0-9]{12}$", var.organization_id))
    error_message = "Organization ID must be exactly 12 digits when provided."
  }
}

variable "folder_ids" {
  type        = list(string)
  description = "List of Google Cloud folders being registered"
  default     = []

  validation {
    condition = alltrue([
      for folder_id in var.folder_ids : can(regex("^[0-9]{12}$", folder_id))
    ])
    error_message = "All folder IDs must be exactly 12 digits."
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

variable "region" {
  type        = string
  description = "GCP region for resource deployment"
  default     = "us-central1"
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
# LOG INGESTION SETTINGS (RTV&D)
# =============================================================================

variable "log_retention_duration" {
  type        = string
  description = "Message retention duration for Pub/Sub subscription (e.g., '1209600s' for 14 days)"
  default     = "1209600s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.log_retention_duration))
    error_message = "Retention duration must be in seconds format (e.g., '604800s')."
  }
}

variable "log_ack_deadline" {
  type        = number
  description = "Message acknowledgment deadline in seconds for Pub/Sub subscription"
  default     = 300

  validation {
    condition     = var.log_ack_deadline >= 10 && var.log_ack_deadline <= 600
    error_message = "Ack deadline must be between 10 and 600 seconds."
  }
}

variable "topic_retention_duration" {
  type        = string
  description = "Message retention duration for Pub/Sub topic (e.g., '2592000s' for 30 days)"
  default     = "2592000s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.topic_retention_duration))
    error_message = "Topic retention duration must be in seconds format (e.g., '2592000s')."
  }
}

variable "audit_log_types" {
  type        = list(string)
  description = "List of audit log types to collect (activity, system_event, policy, data_access)"
  default     = ["activity", "system_event", "policy"]

  validation {
    condition = alltrue([
      for log_type in var.audit_log_types : contains(["activity", "system_event", "policy", "data_access"], log_type)
    ])
    error_message = "Audit log types must be from: activity, system_event, policy, data_access."
  }
}

variable "log_exclusion_filters" {
  type        = list(string)
  description = "List of exclusion filter expressions to exclude specific resources from log collection"
  default     = []

  validation {
    condition     = length(var.log_exclusion_filters) <= 50
    error_message = "Maximum of 50 exclusion filters allowed."
  }
}

# =============================================================================
# RESOURCE NAMING & ORGANIZATION
# =============================================================================

variable "resource_prefix" {
  type        = string
  description = "Prefix for resource names (helps with organization and identification)"
  default     = null

  validation {
    condition     = var.resource_prefix == null || (can(regex("^[a-z0-9-]*$", var.resource_prefix)) && length(var.resource_prefix) <= 20)
    error_message = "Resource prefix must contain only lowercase letters, numbers, hyphens, and be 20 characters or less."
  }
}

variable "resource_suffix" {
  type        = string
  description = "Suffix for resource names (helps with organization and identification)"
  default     = null

  validation {
    condition     = var.resource_suffix == null || (can(regex("^[a-z0-9-]*$", var.resource_suffix)) && length(var.resource_suffix) <= 20)
    error_message = "Resource suffix must contain only lowercase letters, numbers, hyphens, and be 20 characters or less."
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
    condition     = length(var.labels) <= 60
    error_message = "Maximum of 60 custom labels allowed (system labels will be added automatically)."
  }
}
