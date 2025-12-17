# =============================================================================
# Outputs for CrowdStrike GCP CSPM Module Registration Example
# =============================================================================

output "registration_id" {
  description = "The unique CrowdStrike registration ID for this GCP setup"
  value       = module.crowdstrike_gcp_registration.registration_id
}

output "wif_project_id" {
  description = "The GCP Project ID where Workload Identity resources were created"
  value       = module.crowdstrike_gcp_registration.wif_project_id
}

output "wif_project_number" {
  description = "The GCP Project Number for the Workload Identity project"
  value       = module.crowdstrike_gcp_registration.wif_project_number
}

output "log_topic_name" {
  description = "The full resource name of the Pub/Sub topic for log ingestion (if RTV&D enabled)"
  value       = module.crowdstrike_gcp_registration.log_topic_id
}

output "log_subscription_name" {
  description = "The full resource name of the Pub/Sub subscription for log ingestion (if RTV&D enabled)"
  value       = module.crowdstrike_gcp_registration.log_subscription_id
}

output "log_sink_names" {
  description = "Names of the created log sinks (if RTV&D enabled)"
  value       = module.crowdstrike_gcp_registration.log_sink_names
}
