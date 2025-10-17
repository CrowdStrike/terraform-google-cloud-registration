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
}

variable "resource_suffix" {
  type        = string
  description = "Suffix to be added to all created resource names for identification"
  default     = ""
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID to add as a trust relationship in the WIF Pool Provider"

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be exactly 12 digits."
  }
}

variable "wif_pool_name" {
  type        = string
  description = "Display name for the CrowdStrike Workload Identity Federation Pool (max 32 characters)"

  validation {
    condition     = length(var.wif_pool_name) <= 32
    error_message = "Pool display name must be 32 characters or less."
  }
}

variable "wif_pool_provider_name" {
  type        = string
  description = "Display name for the CrowdStrike Workload Identity Federation Provider (max 32 characters)"

  validation {
    condition     = length(var.wif_pool_provider_name) <= 32
    error_message = "Provider display name must be 32 characters or less."
  }
}
