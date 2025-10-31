variable "wif_iam_principal" {
  type        = string
  description = "Google Cloud IAM Principal that identifies CrowdStrike resources"
  
  validation {
    condition     = can(regex("^(principal://|principalSet://|serviceAccount:)", var.wif_iam_principal))
    error_message = "IAM principal must be a valid principal, principalSet, or serviceAccount format."
  }
}

variable "registration_type" {
  type        = string
  description = "The scope of the Google Cloud registration which can be one of the following values: organization, folder, project"
  validation {
    condition     = contains(["organization", "folder", "project"], var.registration_type)
    error_message = "Registration type must be one of: organization, folder, project."
  }
}

variable "organization_id" {
  type        = string
  description = "The Google Cloud organization being registered"
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

variable "google_iam_roles" {
  type        = list(string)
  description = "List of Google Cloud IAM roles that will be granted to the wif_iam_principal identity for asset inventory access"
  default     = [
    "roles/browser",
    "roles/cloudasset.viewer",
    "roles/aiplatform.viewer",
    "roles/alloydb.viewer",
    "roles/apigee.readOnlyAdmin",
    "roles/appengine.appViewer",
    "roles/cloudtasks.viewer",
    "roles/compute.viewer",
    "roles/dataplex.viewer",
    "roles/essentialcontacts.viewer",
    "roles/firebaseappcheck.viewer",
    "roles/firebaseauth.viewer",
    "roles/firebasedatabase.viewer",
    "roles/firebasehosting.viewer",
    "roles/firebasestorage.viewer",
    "roles/notebooks.viewer",
    "roles/recommender.iampolicychangeriskViewer",
    "roles/recommender.iamViewer",
    "roles/securitycenter.adminViewer",
    "roles/cloudfunctions.developer"
  ]
  
  validation {
    condition = alltrue([
      for role in var.google_iam_roles : can(regex("^roles/", role))
    ])
    error_message = "All IAM roles must start with 'roles/'."
  }
}