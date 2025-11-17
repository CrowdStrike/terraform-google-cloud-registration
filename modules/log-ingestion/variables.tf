variable "wif_iam_principal" {
  type        = string
  description = "Google Cloud IAM Principal that identifies CrowdStrike resources"

  validation {
    condition     = can(regex("^(principal://|principalSet://|serviceAccount:)", var.wif_iam_principal))
    error_message = "IAM principal must be a valid principal, principalSet, or serviceAccount format."
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

variable "registration_id" {
  type        = string
  description = "Unique registration ID returned by CrowdStrike Registration API"

  validation {
    condition     = length(var.registration_id) > 0 && can(regex("^[a-z0-9-]+$", var.registration_id))
    error_message = "Registration ID must be non-empty and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "organization_id" {
  type        = string
  description = "The Google Cloud organization being registered"
  default     = ""

  validation {
    condition     = var.organization_id == "" || can(regex("^[0-9]{12}$", var.organization_id))
    error_message = "Organization ID must be exactly 12 digits when provided."
  }
}

variable "folder_ids" {
  type        = list(string)
  description = "List of Google Cloud folders being registered"
  default     = []

  validation {
    condition = length(var.folder_ids) == 0 || alltrue([
      for folder_id in var.folder_ids : can(regex("^[0-9]{12}$", folder_id))
    ])
    error_message = "All folder IDs must be exactly 12 digits when provided."
  }
}

variable "project_ids" {
  type        = list(string)
  description = "List of Google Cloud projects being registered"
  default     = []

  validation {
    condition = length(var.project_ids) == 0 || alltrue([
      for project_id in var.project_ids : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", project_id))
    ])
    error_message = "All project IDs must be 6-30 characters, start with lowercase letter, contain only lowercase letters/numbers/hyphens, and not end with hyphen."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix to be added to all created resource names for identification"
  default     = ""

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

variable "infra_project_id" {
  type        = string
  description = "Project ID used for CrowdStrike infrastructure resources (topic, subscription, and other components)"
  default     = ""

  validation {
    condition     = var.infra_project_id == "" || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.infra_project_id))
    error_message = "Project ID must be 6-30 characters, start with lowercase letter, contain only lowercase letters/numbers/hyphens, and not end with hyphen."
  }
}

variable "message_retention_duration" {
  type        = string
  description = "Message retention duration for Pub/Sub subscription (e.g., '604800s' for 7 days)"
  default     = "604800s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.message_retention_duration))
    error_message = "Message retention duration must be in seconds format (e.g., '604800s')."
  }
}

variable "ack_deadline_seconds" {
  type        = number
  description = "Message acknowledgment deadline in seconds"
  default     = 600

  validation {
    condition     = var.ack_deadline_seconds >= 10 && var.ack_deadline_seconds <= 600
    error_message = "Ack deadline must be between 10 and 600 seconds."
  }
}

variable "audit_log_types" {
  type        = list(string)
  description = "List of audit log types to include in the filter"
  default     = ["activity", "system_event", "policy"]

  validation {
    condition = alltrue([
      for log_type in var.audit_log_types : contains(["activity", "system_event", "policy", "data_access"], log_type)
    ])
    error_message = "Audit log types must be one of: activity, system_event, policy, data_access."
  }
}

variable "exclusion_filters" {
  type        = list(string)
  description = "List of exclusion filter expressions to exclude specific resources from log collection (e.g., 'resource.labels.project_id=\"excluded-project\"')"
  default     = []
}

variable "topic_message_retention_duration" {
  type        = string
  description = "Message retention duration for Pub/Sub topic (e.g., '604800s' for 7 days)"
  default     = "604800s"

  validation {
    condition     = can(regex("^[0-9]+s$", var.topic_message_retention_duration))
    error_message = "Topic message retention duration must be in seconds format (e.g., '604800s')."
  }
}

variable "topic_storage_regions" {
  type        = list(string)
  description = "Regions for topic message storage. If empty, uses default region"
  default     = []
}

variable "enable_schema_validation" {
  type        = bool
  description = "Enable schema validation for the topic"
  default     = false
}

variable "schema_definition" {
  type        = string
  description = "Avro or Protocol Buffer schema definition (required if enable_schema_validation is true)"
  default     = ""

  validation {
    condition     = !var.enable_schema_validation || var.schema_definition != ""
    error_message = "Schema definition is required when schema validation is enabled."
  }
}

variable "schema_type" {
  type        = string
  description = "Schema type: 'AVRO' or 'PROTOCOL_BUFFER'"
  default     = "AVRO"

  validation {
    condition     = contains(["AVRO", "PROTOCOL_BUFFER"], var.schema_type)
    error_message = "Schema type must be either 'AVRO' or 'PROTOCOL_BUFFER'."
  }
}

variable "existing_topic_name" {
  type        = string
  description = "Name of existing Pub/Sub topic to use. If empty, creates new topic"
  default     = ""
}

variable "existing_subscription_name" {
  type        = string
  description = "Name of existing Pub/Sub subscription to use. If empty, creates new subscription"
  default     = ""
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