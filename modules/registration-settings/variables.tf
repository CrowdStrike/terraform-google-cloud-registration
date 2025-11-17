variable "falcon_api_host" {
  description = "CrowdStrike Falcon API host URL for OAuth"
  type        = string
  default     = "https://api.dodo.crowdstrike.red"
}

variable "falcon_cloud_api_host" {
  description = "CrowdStrike API host URL"
  type        = string
  default     = "https://cscloudregistration-s001-main.red.dodo.eyrie.cloud"
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
  description = "CrowdStrike Customer ID for internal API authentication"
  type        = string
  default     = null
}

variable "registration_id" {
  description = "CrowdStrike registration ID from initial registration"
  type        = string
}

variable "wif_pool_id" {
  description = "Workload Identity Federation pool ID from registration"
  type        = string
}

variable "wif_project_number" {
  description = "GCP project number where WIF resources are created"
  type        = string
}

variable "wif_project_id" {
  description = "GCP project ID where WIF resources are created"
  type        = string
  default     = ""
}

variable "wif_provider_id" {
  description = "Workload Identity Federation provider ID"
  type        = string
  default     = ""
}

variable "completion_trigger" {
  description = "Trigger for completion provisioner (depends_on from other modules)"
  type        = any
  default     = null
}

variable "log_topic_id" {
  description = "Pub/Sub topic ID for log ingestion"
  type        = string
  default     = ""
}

variable "log_subscription_id" {
  description = "Pub/Sub subscription ID for log ingestion"
  type        = string
  default     = ""
}

variable "log_sink_name" {
  description = "Log sink name for log ingestion"
  type        = string
  default     = ""
}