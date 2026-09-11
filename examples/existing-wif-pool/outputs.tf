# =============================================================================
# Output Values for Bring-Your-Own WIF Example
# =============================================================================

output "wif_pool_id" {
  description = "The existing Workload Identity Pool ID that was attached to"
  value       = module.crowdstrike_gcp_registration.wif_pool_id
}

output "wif_pool_provider_id" {
  description = "The existing Workload Identity Pool Provider ID that was attached to"
  value       = module.crowdstrike_gcp_registration.wif_pool_provider_id
}

output "wif_iam_principal" {
  description = "The IAM principal that CrowdStrike uses to access GCP resources"
  value       = module.crowdstrike_gcp_registration.wif_iam_principal
}
