variable "wif_project_id" {
  type        = string
  default     = ""
  description = "Project ID to create WIF resources"
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

variable "wif_pool_id" {
  type        = string
  default     = "abc"
  description = "Google Cloud Workload Identity Federation Pool ID that is used to identify a CrowdStrike identity pool"
}

variable "wif_pool_provider_id" {
  type        = string
  default     = ""
  description = "Google Cloud Workload Identity Federation Provider ID that is used to identify the CrowdStrike provider."
}

variable "aws_account_id" {
  type        = string
  default     = ""
  description = ""
}

variable "wif_pool_name" {
  type        = string
  default     = ""
  description = ""
}

variable "wif_pool_provider_name" {
  type        = string
  default     = ""
  description = ""
}