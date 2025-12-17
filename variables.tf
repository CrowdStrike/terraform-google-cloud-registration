variable "infra_project_id" {
  type        = string
  description = "Google Cloud Project ID where CrowdStrike infrastructure resources will be deployed"

  validation {
    condition     = length(var.infra_project_id) >= 6 && length(var.infra_project_id) <= 30 && can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.infra_project_id))
    error_message = "Project ID must be 6-30 characters, start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and not end with a hyphen."
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

variable "resource_prefix" {
  description = "Prefix to be added to all created resource names for identification"
  default     = null
  type        = string

  validation {
    condition     = var.resource_prefix == null || (can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]*$", var.resource_prefix)) && length(var.resource_prefix) <= 13)
    error_message = "Resource prefix must start with alphanumeric character and contain only letters, numbers, underscores, hyphens, and periods, and be 13 characters or less."
  }
}

variable "resource_suffix" {
  type        = string
  description = "Suffix to be added to all created resource names for identification"
  default     = null

  validation {
    condition     = var.resource_suffix == null || (can(regex("^[A-Za-z0-9_.-]*$", var.resource_suffix)) && length(var.resource_suffix) <= 13)
    error_message = "Resource suffix must contain only letters, numbers, underscores, hyphens, and periods, and be 13 characters or less."
  }
}

variable "role_arn" {
  type        = string
  description = "AWS Role ARN used by CrowdStrike for authentication"

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn):(iam|sts)::[0-9]{12}:(role|assumed-role)/.+", var.role_arn))
    error_message = "Role ARN must be a valid AWS IAM role ARN or STS assumed role ARN format."
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
  description = "List of Google Cloud projects being registered"
  default     = []

  validation {
    condition = alltrue([
      for project_id in var.project_ids : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", project_id))
    ])
    error_message = "All project IDs must be 6-30 characters, start with lowercase letter, contain only lowercase letters/numbers/hyphens, and not end with hyphen."
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
    schema_definition                = optional(string)
    existing_topic_name              = optional(string)
    existing_subscription_name       = optional(string)
    exclusion_filters                = optional(list(string), [])
  })
  default = {}
}
