output "registration_id" {
  description = "CrowdStrike registration ID obtained from API"
  value       = trimspace(data.local_file.registration_id.content)
}

output "wif_pool_id" {
  description = "Workload Identity Federation pool ID obtained from API"
  value       = trimspace(data.local_file.wif_pool_id.content)
}

output "wif_provider_id" {
  description = "Workload Identity Federation provider ID obtained from API"
  value       = trimspace(data.local_file.wif_provider_id.content)
}
