# =============================================================================
# Outputs for CrowdStrike GCP CSPM Project Registration
# =============================================================================
# These outputs provide important information about the created resources
# and can be used by GCP Infrastructure Manager for monitoring and integration.
# =============================================================================

# =============================================================================
# WORKLOAD IDENTITY OUTPUTS
# =============================================================================

output "wif_pool_id" {
  description = "The ID of the created Workload Identity Pool"
  value       = module.crowdstrike_gcp_registration.wif_pool_id
}

output "wif_pool_provider_id" {
  description = "The ID of the created Workload Identity Pool Provider"
  value       = module.crowdstrike_gcp_registration.wif_pool_provider_id
}

output "wif_iam_principal" {
  description = "The IAM principal that CrowdStrike uses to access GCP resources"
  value       = module.crowdstrike_gcp_registration.wif_iam_principal
}

output "wif_project_id" {
  description = "The GCP Project ID where Workload Identity resources were created"
  value       = module.crowdstrike_gcp_registration.wif_project_id
}

output "wif_project_number" {
  description = "The GCP Project Number for the Workload Identity project"
  value       = module.crowdstrike_gcp_registration.wif_project_number
}

# =============================================================================
# REGISTRATION OUTPUTS
# =============================================================================

output "registration_id" {
  description = "The unique CrowdStrike registration ID for this GCP setup"
  value       = module.crowdstrike_gcp_registration.registration_id
  sensitive   = true
}

output "registration_type" {
  description = "The type of registration (project, folder, or organization)"
  value       = "project"
}

output "registered_project_ids" {
  description = "List of GCP Project IDs that were registered with CrowdStrike"
  value       = var.project_ids
}

output "discovered_projects" {
  description = "Detailed information about discovered and registered projects"
  value       = module.crowdstrike_gcp_registration.discovered_projects
}

# =============================================================================
# LOG INGESTION OUTPUTS (RTV&D)
# =============================================================================

output "log_ingestion_enabled" {
  description = "Whether Real Time Visibility & Detection log ingestion is enabled"
  value       = var.enable_realtime_visibility
}

output "pubsub_topic_id" {
  description = "The ID of the Pub/Sub topic for log ingestion (if RTV&D enabled)"
  value       = var.enable_realtime_visibility ? module.crowdstrike_gcp_registration.log_topic_id : null
}

output "pubsub_subscription_id" {
  description = "The ID of the Pub/Sub subscription for log ingestion (if RTV&D enabled)"
  value       = var.enable_realtime_visibility ? module.crowdstrike_gcp_registration.log_subscription_id : null
}

output "log_sink_names" {
  description = "Names of the created log sinks (if RTV&D enabled)"
  value       = var.enable_realtime_visibility ? module.crowdstrike_gcp_registration.log_sink_names : null
}

# =============================================================================
# INFRASTRUCTURE OUTPUTS
# =============================================================================

output "infra_project_id" {
  description = "The GCP Project ID where CrowdStrike infrastructure was created"
  value       = var.infra_project_id
}

output "region" {
  description = "The GCP region where resources were deployed"
  value       = var.region
}

output "environment" {
  description = "The environment name for this deployment"
  value       = var.environment
}

output "resource_labels" {
  description = "Labels applied to all created resources"
  value = merge(var.labels, {
    managed-by  = "infrastructure-manager"
    module      = "crowdstrike-cspm"
    environment = var.environment
  })
}

# =============================================================================
# MONITORING OUTPUTS
# =============================================================================

output "deployment_timestamp" {
  description = "Timestamp when the deployment was completed"
  value       = timestamp()
}

output "terraform_version" {
  description = "Terraform version used for this deployment"
  value       = terraform.version
}

output "module_version" {
  description = "Version information for tracking deployments"
  value = {
    terraform_version = terraform.version
    deployment_date   = timestamp()
    registration_type = "project"
    rtv_enabled       = var.enable_realtime_visibility
  }
}

# =============================================================================
# INTEGRATION OUTPUTS
# =============================================================================

output "falcon_api_host" {
  description = "The CrowdStrike Falcon API host used for this deployment"
  value       = var.falcon_cloud_api_host
}

output "aws_integration" {
  description = "AWS integration details for CrowdStrike identity federation"
  value = {
    role_arn = var.role_arn
  }
  sensitive = true
}