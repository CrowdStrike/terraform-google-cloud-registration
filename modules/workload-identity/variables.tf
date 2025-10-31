variable "wif_pool_id" {
  type        = string
  description = "Google Cloud Workload Identity Federation Pool ID that is used to identify a CrowdStrike identity pool"

  validation {
    condition     = length(var.wif_pool_id) >= 4 && length(var.wif_pool_id) <= 32 && can(regex("^[a-z0-9-]+$", var.wif_pool_id))
    error_message = "Pool ID must be 4-32 characters and contain only lowercase letters, numbers, and hyphens."
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

variable "wif_pool_provider_id" {
  type        = string
  description = "Google Cloud Workload Identity Federation Provider ID that is used to identify the CrowdStrike provider"

  validation {
    condition     = length(var.wif_pool_provider_id) >= 4 && length(var.wif_pool_provider_id) <= 32 && can(regex("^[a-z0-9-]+$", var.wif_pool_provider_id))
    error_message = "Provider ID must be 4-32 characters and contain only lowercase letters, numbers, and hyphens."
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

variable "registration_id" {
  type        = string
  description = "Unique registration ID returned by CrowdStrike Registration API"

  validation {
    condition     = length(var.registration_id) > 0 && can(regex("^[a-z0-9-]+$", var.registration_id))
    error_message = "Registration ID must be non-empty and contain only lowercase letters, numbers, and hyphens."
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
