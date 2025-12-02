variable "registration_type" {
  type        = string
  description = "Type of registration: organization, folder, or project"
  validation {
    condition     = contains(["organization", "folder", "project"], var.registration_type)
    error_message = "Registration type must be one of: organization, folder, project."
  }
}

variable "organization_id" {
  type        = string
  description = "GCP Organization ID for organization-level registration"
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
    condition = alltrue([
      for folder_id in var.folder_ids : can(regex("^[0-9]{12}$", folder_id))
    ])
    error_message = "All folder IDs must be exactly 12 digits."
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
