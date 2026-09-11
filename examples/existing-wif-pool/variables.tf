# =============================================================================
# Input Variables for Bring-Your-Own WIF Example
# =============================================================================

variable "falcon_client_id" {
  type        = string
  description = "CrowdStrike Falcon API client ID"
  sensitive   = true
}

variable "falcon_client_secret" {
  type        = string
  description = "CrowdStrike Falcon API client secret"
  sensitive   = true
}

variable "registration_name" {
  type        = string
  description = "Name for the CrowdStrike GCP registration"
}

variable "deployment_method" {
  type        = string
  description = "Deployment method for the CrowdStrike GCP registration"
  default     = "terraform-native"
}

variable "infra_project_id" {
  type        = string
  description = "Google Cloud Project ID where CrowdStrike infrastructure resources will be deployed"
}

variable "project_ids" {
  type        = list(string)
  description = "List of Google Cloud projects being registered"
}

variable "role_arn" {
  type        = string
  description = "AWS Role ARN used by CrowdStrike for authentication"
}

variable "existing_wif_pool_id" {
  type        = string
  description = "The ID of an existing GCP Workload Identity Pool, created by another registration under the same CID, to attach this registration to instead of creating a new pool"

  validation {
    condition     = length(var.existing_wif_pool_id) >= 4 && length(var.existing_wif_pool_id) <= 32 && can(regex("^[a-z0-9-]+$", var.existing_wif_pool_id))
    error_message = "existing_wif_pool_id must be 4-32 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "resource_prefix" {
  type        = string
  description = "Prefix to be added to all created resource names"
  default     = null
}

variable "resource_suffix" {
  type        = string
  description = "Suffix to be added to all created resource names"
  default     = null
}

variable "labels" {
  type        = map(string)
  description = "Map of labels to be applied to all resources"
  default     = {}
}
