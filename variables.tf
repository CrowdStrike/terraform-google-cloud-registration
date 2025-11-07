variable "wif_project_id" {
  type        = string
  description = "Google Cloud Project ID where the CrowdStrike workload identity federation pool resources are deployed"

  validation {
    condition     = length(var.wif_project_id) >= 6 && length(var.wif_project_id) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.wif_project_id))
    error_message = "Project ID must be 6-30 characters, start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and not end with a hyphen."
  }
}

variable "resource_prefix" {
  description = "Prefix to be added to all created resource names for identification"
  default     = ""
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]*$", var.resource_prefix)) && length(var.resource_prefix) <= 20
    error_message = "Resource prefix must contain only lowercase letters, numbers, and hyphens, and be 20 characters or less."
  }
}

variable "resource_suffix" {
  type        = string
  description = "Suffix to be added to all created resource names for identification"
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9-]*$", var.resource_suffix)) && length(var.resource_suffix) <= 20
    error_message = "Resource suffix must contain only lowercase letters, numbers, and hyphens, and be 20 characters or less."
  }
}

variable "wif_pool_id" {
  type        = string
  description = "Google Cloud Workload Identity Federation Pool ID that is used to identify a CrowdStrike identity pool"

  validation {
    condition     = length(var.wif_pool_id) >= 4 && length(var.wif_pool_id) <= 32 && can(regex("^[a-z0-9-]+$", var.wif_pool_id))
    error_message = "Pool ID must be 4-32 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "wif_pool_provider_id" {
  type        = string
  description = "Google Cloud Workload Identity Federation Provider ID that is used to identify the CrowdStrike provider"

  validation {
    condition     = length(var.wif_pool_provider_id) >= 4 && length(var.wif_pool_provider_id) <= 32 && can(regex("^[a-z0-9-]+$", var.wif_pool_provider_id))
    error_message = "Provider ID must be 4-32 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID to add as a trust relationship in the WIF Pool Provider"

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be exactly 12 digits."
  }
}

variable "role_arn" {
  type        = string
  description = "AWS Role ARN used by CrowdStrike for authentication"

  validation {
    condition     = can(regex("^arn:aws:(iam|sts)::[0-9]{12}:(role|assumed-role)/.+", var.role_arn))
    error_message = "Role ARN must be a valid AWS IAM role ARN or STS assumed role ARN format."
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

variable "registration_id" {
  type        = string
  description = "Unique registration ID returned by CrowdStrike Registration API, used for resource naming"

  validation {
    condition     = length(var.registration_id) > 0 && can(regex("^[a-z0-9-]+$", var.registration_id))
    error_message = "Registration ID must be non-empty and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "organization_id" {
  type        = string
  description = "GCP Organization ID for organization-level registration"
  default     = ""

  validation {
    condition     = var.registration_type != "organization" || (var.organization_id != "" && can(regex("^[0-9]{12}$", var.organization_id)))
    error_message = "Organization ID must be provided and be exactly 12 digits when registration_type is 'organization'."
  }
}

variable "folder_ids" {
  type        = list(string)
  description = "List of Google Cloud folders being registered"
  default     = []

  validation {
    condition = var.registration_type != "folder" || (length(var.folder_ids) > 0 && alltrue([
      for folder_id in var.folder_ids : can(regex("^[0-9]{12}$", folder_id))
    ]))
    error_message = "Folder IDs must be provided and all must be exactly 12 digits when registration_type is 'folder'."
  }
}

variable "project_ids" {
  type        = list(string)
  description = "List of Google Cloud projects being registered"
  default     = []

  validation {
    condition = var.registration_type != "project" || (length(var.project_ids) > 0 && alltrue([
      for project_id in var.project_ids : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", project_id))
    ]))
    error_message = "Project IDs must be provided and all must be 6-30 characters, start with lowercase letter, contain only lowercase letters/numbers/hyphens, and not end with hyphen when registration_type is 'project'."
  }
}

variable "enable_realtime_visibility" {
  type        = bool
  description = "Enable Real Time Visibility and Detection (RTV&D) features via log ingestion"
  default     = false
}

variable "labels" {
  type        = map(string)
  description = "Map of labels to be applied to all resources created by this module"
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
    schema_definition                = optional(string, "")
    existing_topic_name              = optional(string, "")
    existing_subscription_name       = optional(string, "")
    exclusion_filters                = optional(list(string), [])
  })
  default = {}
}