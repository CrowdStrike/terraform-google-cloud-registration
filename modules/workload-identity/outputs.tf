output "wif_project_number" {
  value       = data.google_project.wif_project.number
  description = "Project number for the WIF Project ID"
}

output "wif_iam_principal" {
  value       = "principal://iam.googleapis.com/${google_iam_workload_identity_pool.main.name}/subject/${var.registration_id}"
  description = "Google Cloud IAM Principal that identifies the specific CrowdStrike session for this registration"
}