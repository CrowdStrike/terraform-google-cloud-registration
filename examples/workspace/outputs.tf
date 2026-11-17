# Outputs of the CrowdStrike Google Workspace registration example

output "sa_email" {
  description = "Email of the Workspace service account. In the Admin Console, assign it a custom read-only admin role."
  value       = module.crowdstrike_gws_registration.sa_email
}

output "sa_unique_id" {
  description = "Numeric unique ID of the Workspace service account."
  value       = module.crowdstrike_gws_registration.sa_unique_id
}

output "wif_principal" {
  description = "WIF principal of the CrowdStrike Workspace identity for this registration."
  value       = module.crowdstrike_gws_registration.wif_principal
}

output "identity_pool_name" {
  description = "Full resource name of the Workspace Workload Identity Pool."
  value       = module.crowdstrike_gws_registration.identity_pool_name
}

output "provider_name" {
  description = "Full resource name of the Workspace Workload Identity Pool Provider."
  value       = module.crowdstrike_gws_registration.provider_name
}

output "project_number" {
  description = "Project number of the WIF project."
  value       = module.crowdstrike_gws_registration.project_number
}
