variable "falcon_cloud_api_host" {
  description = "CrowdStrike Cloud Registration API host URL"
  type        = string
  default     = "https://cscloudregistration-s001-main.red.dodo.eyrie.cloud"
}

variable "falcon_api_host" {
  description = "CrowdStrike Falcon API host URL for OAuth"
  type        = string
  default     = "https://api.dodo.crowdstrike.red"
}

variable "falcon_client_id" {
  description = "CrowdStrike Falcon API client ID"
  type        = string
}

variable "falcon_client_secret" {
  description = "CrowdStrike Falcon API client secret"
  type        = string
  sensitive   = true
}

variable "customer_id" {
  description = "CrowdStrike Customer ID for internal API"
  type        = string
  default     = null
}

variable "enable_realtime_visibility" {
  description = "Enable Real Time Visibility and Detection (RTV&D) features"
  type        = bool
  default     = false
}

variable "registration_type" {
  description = "Type of registration (organization, folder, or project)"
  type        = string
  validation {
    condition     = contains(["organization", "folder", "project"], var.registration_type)
    error_message = "Registration type must be one of: organization, folder, project."
  }
}

variable "organization_id" {
  description = "GCP Organization ID (required for organization registration)"
  type        = string
  default     = null
}

variable "folder_ids" {
  description = "List of GCP Folder IDs (required for folder registration)"
  type        = list(string)
  default     = []
}

variable "project_ids" {
  description = "List of GCP Project IDs (required for project registration)"
  type        = list(string)
  default     = []
}

variable "wif_project_id" {
  description = "GCP project ID where WIF resources will be created"
  type        = string
}

variable "infra_project_id" {
  description = "GCP project ID where infrastructure resources (Pub/Sub, etc.) will be created"
  type        = string
}

variable "completion_trigger" {
  description = "Trigger for completion provisioner (depends_on from other modules)"
  type        = any
  default     = null
}

variable "resource_prefix" {
  description = "Resource name prefix"
  type        = string
  default     = "cs"
}

variable "resource_suffix" {
  description = "Resource name suffix"  
  type        = string
  default     = ""
}