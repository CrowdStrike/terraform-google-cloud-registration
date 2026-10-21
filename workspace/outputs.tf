# Output names match the fields that CrowdStrike stores; do not rename them

output "sa_email" {
  description = "Email of the Workspace service account. In the Admin Console, assign it a custom read-only admin role."
  value       = module.workspace.sa_email
}

output "sa_unique_id" {
  description = "Numeric unique ID of the Workspace service account."
  value       = module.workspace.sa_unique_id
}

output "wif_principal" {
  description = "WIF principal of the CrowdStrike Workspace identity for this registration."
  value       = module.workload-identity.wif_iam_principal
}

output "identity_pool_name" {
  description = "Full resource name of the Workspace Workload Identity Pool."
  value       = module.workload-identity.wif_pool_name
}

output "provider_name" {
  description = "Full resource name of the Workspace Workload Identity Pool Provider."
  value       = module.workload-identity.wif_provider_name
}

output "project_number" {
  description = "Project number of the WIF project."
  value       = module.workload-identity.wif_project_number
}
