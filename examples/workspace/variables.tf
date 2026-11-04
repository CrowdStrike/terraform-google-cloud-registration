# Variables of the example. The module validates every value that it takes

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

variable "falcon_cloud" {
  type        = string
  description = "CrowdStrike cloud environment. Set to 'us-gov-1' or 'us-gov-2' for government cloud deployments. Defaults to commercial cloud when null."
  default     = null

  validation {
    condition = var.falcon_cloud == null ? true : contains([
      "us-gov-1", "us-gov-2"
    ], var.falcon_cloud)
    error_message = "Falcon cloud must be null (for commercial) or one of: us-gov-1, us-gov-2."
  }
}

variable "gcp_registration_id" {
  type        = string
  description = "ID of the CrowdStrike Google Cloud registration that has the Google Workspace registration, as given by the CrowdStrike console."
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
