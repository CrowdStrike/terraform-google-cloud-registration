# =============================================================================
# CrowdStrike GCP CSPM Registration Module - Outputs
# =============================================================================

# =============================================================================
# Workload Identity Outputs
# =============================================================================

output "wif_pool_id" {
  description = "The ID of the created Workload Identity Pool"
  value       = crowdstrike_cloud_google_registration.main.wif_pool_id
}

output "wif_pool_provider_id" {
  description = "The ID of the created Workload Identity Pool Provider"
  value       = crowdstrike_cloud_google_registration.main.wif_provider_id
}

output "wif_iam_principal" {
  description = "The IAM principal that CrowdStrike uses to access GCP resources"
  value       = module.workload-identity.wif_iam_principal
}

output "wif_project_id" {
  description = "The GCP Project ID where Workload Identity resources were created"
  value       = module.workload-identity.wif_project_id
}

output "wif_project_number" {
  description = "The GCP Project Number for the Workload Identity project"
  value       = module.workload-identity.wif_project_number
}

# =============================================================================
# Registration Outputs
# =============================================================================

output "registration_id" {
  description = "The unique CrowdStrike registration ID for this GCP setup"
  value       = crowdstrike_cloud_google_registration.main.id
  sensitive   = true
}

# =============================================================================
# Log Ingestion Outputs (Optional - only when RTV&D is enabled)
# =============================================================================

output "log_topic_id" {
  description = "The ID of the Pub/Sub topic for log ingestion (if RTV&D enabled)"
  value       = var.enable_realtime_visibility ? module.log-ingestion[0].pubsub_topic_id : null
}

output "log_subscription_id" {
  description = "The ID of the Pub/Sub subscription for log ingestion (if RTV&D enabled)"
  value       = var.enable_realtime_visibility ? module.log-ingestion[0].subscription_id : null
}

output "log_sink_names" {
  description = "Names of the created log sinks (if RTV&D enabled)"
  value       = var.enable_realtime_visibility ? module.log-ingestion[0].log_sink_names : null
}
