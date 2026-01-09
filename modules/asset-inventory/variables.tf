variable "wif_iam_principal" {
  type        = string
  description = "Google Cloud IAM Principal that identifies CrowdStrike resources"

  validation {
    condition     = can(regex("^(principal://|principalSet://|serviceAccount:)", var.wif_iam_principal))
    error_message = "IAM principal must be a valid principal, principalSet, or serviceAccount format."
  }
}

variable "discovered_projects" {
  type        = list(string)
  description = "List of all discovered projects where APIs will be enabled"
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
  default     = null

  validation {
    condition     = var.organization_id == null || can(regex("^[1-9][0-9]*$", var.organization_id))
    error_message = "Organization ID must be a numeric string without leading zeros when provided."
  }
}

variable "folder_ids" {
  type        = list(string)
  description = "List of Google Cloud folders being registered"
  default = [
    "roles/aiplatform.viewer",
    "roles/alloydb.viewer",
    "roles/apigee.readOnlyAdmin",
    "roles/appengine.appViewer",
    "roles/artifactregistry.reader",
    "roles/browser",
    "roles/cloudasset.viewer",
    "roles/cloudfunctions.developer",
    "roles/cloudtasks.viewer",
    "roles/compute.viewer",
    "roles/dataplex.viewer",
    "roles/essentialcontacts.viewer",
    "roles/firebaseappcheck.viewer",
    "roles/firebaseauth.viewer",
    "roles/firebasedatabase.viewer",
    "roles/firebasehosting.viewer",
    "roles/firebasestorage.viewer",
    "roles/iam.securityReviewer.organizations",
    "roles/iam.securityReviewer.projects",
    "roles/notebooks.viewer",
    "roles/recommender.iamViewer",
    "roles/recommender.iampolicychangeriskViewer",
    "roles/securitycenter.adminViewer",
    "roles/translate.viewer"
  ]

  validation {
    condition = alltrue([
      for folder_id in var.folder_ids : can(regex("^[1-9][0-9]*$", folder_id))
    ])
    error_message = "All folder IDs must be numeric strings without leading zeros."
  }
}


variable "google_iam_roles" {
  type        = list(string)
  description = "List of Google Cloud IAM roles that will be granted to the wif_iam_principal identity for asset inventory access"
  default = [
    "roles/aiplatform.viewer",
    "roles/alloydb.viewer",
    "roles/apigee.readOnlyAdmin",
    "roles/appengine.appViewer",
    "roles/artifactregistry.reader",
    "roles/browser",
    "roles/cloudasset.viewer",
    "roles/cloudfunctions.developer",
    "roles/cloudtasks.viewer",
    "roles/compute.viewer",
    "roles/dataplex.viewer",
    "roles/essentialcontacts.viewer",
    "roles/firebaseappcheck.viewer",
    "roles/firebaseauth.viewer",
    "roles/firebasedatabase.viewer",
    "roles/firebasehosting.viewer",
    "roles/firebasestorage.viewer",
    "roles/iam.securityReviewer.organizations",
    "roles/iam.securityReviewer.projects",
    "roles/notebooks.viewer",
    "roles/recommender.iamViewer",
    "roles/recommender.iampolicychangeriskViewer",
    "roles/securitycenter.adminViewer",
    "roles/translate.viewer"
  ]

  validation {
    condition = alltrue([
      for role in var.google_iam_roles : can(regex("^roles/", role))
    ])
    error_message = "All IAM roles must start with 'roles/'."
  }
}
