output "wif_project_id" {
  value       = var.wif_project_id
  description = "Project ID for the WIF Project"
}

output "wif_project_number" {
  value       = data.google_project.wif_project.number
  description = "Project number for the WIF Project ID"
}

output "wif_pool_id" {
  value       = google_iam_workload_identity_pool.main.workload_identity_pool_id
  description = "The ID of the Workload Identity Pool"
}

output "wif_pool_provider_id" {
  value       = google_iam_workload_identity_pool_provider.aws.workload_identity_pool_provider_id
  description = "The ID of the Workload Identity Pool Provider"
}

output "wif_iam_principal" {
  value       = "principal://iam.googleapis.com/projects/${data.google_project.wif_project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.main.workload_identity_pool_id}/subject/${var.role_arn}/${var.registration_id}"
  description = "Google Cloud IAM Principal that identifies the specific CrowdStrike session for this registration"
}
