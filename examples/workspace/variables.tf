# Variables of the example. The module validates every value

variable "gws_registration_id" {
  type        = string
  description = "ID of the CrowdStrike Google Workspace registration, as given by the CrowdStrike console."
}

variable "wif_pool_id" {
  type        = string
  description = "ID of the Workload Identity Pool, as given by the CrowdStrike console."
}

variable "wif_provider_id" {
  type        = string
  description = "ID of the Workload Identity Pool Provider, as given by the CrowdStrike console."
}

variable "gws_identity_source" {
  type        = string
  description = "Identity source of the registration, as given by the CrowdStrike console: aws-sts or gcp-oidc."
}

variable "service_account_id" {
  type        = string
  description = "Account ID of the Workspace service account, as given by the CrowdStrike console."
}

variable "workspace_role_arn" {
  type        = string
  description = "AWS Role ARN of the CrowdStrike Workspace reader, for aws-sts clouds. Set this or workspace_service_account_unique_id, not both."
  default     = null
}

variable "workspace_service_account_unique_id" {
  type        = string
  description = "Unique ID of the CrowdStrike Workspace intermediate service account, for gcp-oidc clouds. Set this or workspace_role_arn, not both."
  default     = null
}

variable "wif_project_id" {
  type        = string
  description = "Google Cloud Project ID that holds the Workspace WIF pool and service account."
}

variable "organization_id" {
  type        = string
  description = "ID of the GCP organization that belongs to the Google Workspace, with no organizations/ prefix."
}

variable "customer_id" {
  type        = string
  description = "Google Workspace customer ID, with no customers/ prefix."
}

variable "grant_organization_viewer" {
  type        = bool
  description = "Grant roles/resourcemanager.organizationViewer on organization_id to the Workspace service account."
  default     = true
}

variable "resource_prefix" {
  type        = string
  description = "Prefix for the display names of the WIF pool and provider."
  default     = null
}

variable "resource_suffix" {
  type        = string
  description = "Suffix for the display names of the WIF pool and provider."
  default     = null
}
