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
    condition     = var.registration_type != "organization" || (var.organization_id != "" && can(regex("^[0-9]{12}$", var.organization_id)))
    error_message = "Organization ID must be provided and be exactly 12 digits when registration_type is 'organization'."
  }
}

variable "folder_ids" {
  type        = string
  description = "Comma separated list of the Google Cloud folders being registered"
  default     = ""

  validation {
    condition = var.registration_type != "folder" || (var.folder_ids != "" && alltrue([
      for folder_id in split(",", var.folder_ids) : can(regex("^[0-9]{12}$", trimspace(folder_id)))
    ]))
    error_message = "Folder IDs must be provided and all must be exactly 12 digits when registration_type is 'folder'."
  }
}

variable "project_ids" {
  type        = string
  description = "Comma separated list of the Google Cloud projects being registered"
  default     = ""

  validation {
    condition = var.registration_type != "project" || (var.project_ids != "" && alltrue([
      for project_id in split(",", var.project_ids) : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", trimspace(project_id)))
    ]))
    error_message = "Project IDs must be provided and all must be 6-30 characters, start with lowercase letter, contain only lowercase letters/numbers/hyphens, and not end with hyphen when registration_type is 'project'."
  }
}