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
  value = (
    var.identity_source == "aws-sts"
    ? google_iam_workload_identity_pool_provider.aws[0].workload_identity_pool_provider_id
    : google_iam_workload_identity_pool_provider.oidc[0].workload_identity_pool_provider_id
  )
  description = "The ID of the Workload Identity Pool Provider"
}

output "wif_iam_principal" {
  value = (
    var.identity_source == "aws-sts"
    ? "principal://iam.googleapis.com/projects/${data.google_project.wif_project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.main.workload_identity_pool_id}/subject/${var.role_arn}/${var.registration_id}"
    : "principal://iam.googleapis.com/projects/${data.google_project.wif_project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.main.workload_identity_pool_id}/subject/${var.service_account_unique_id}/${var.registration_id}"
  )
  description = "Google Cloud IAM Principal that identifies the specific CrowdStrike session for this registration"
}

output "wif_pool_name" {
  value       = google_iam_workload_identity_pool.main.name
  description = "Name of the Workload Identity Pool"
}

output "wif_provider_name" {
  value = (
    var.identity_source == "aws-sts"
    ? google_iam_workload_identity_pool_provider.aws[0].name
    : google_iam_workload_identity_pool_provider.oidc[0].name
  )
  description = "Name of the Workload Identity Pool Provider"
}
