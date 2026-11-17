output "sa_email" {
  value       = google_service_account.workspace_reader.email
  description = "Email of the Workspace service account. In the Admin Console, assign it a custom read-only admin role"
}

output "sa_unique_id" {
  value       = google_service_account.workspace_reader.unique_id
  description = "Numeric unique ID of the Workspace service account"
}
