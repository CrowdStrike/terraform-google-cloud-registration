# =============================================================================
# CrowdStrike GCP CSPM Registration - Project Level Example
# =============================================================================
# This example demonstrates project-level registration using the CrowdStrike
# GCP CSPM Terraform module. Designed for deployment via GCP Infrastructure Manager.
#
# Infrastructure Manager will provide variables via URL parameters or
# deployment configuration.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# Provider Configuration
# =============================================================================

provider "google" {
  project = var.infra_project_id
  region  = var.region
}

# =============================================================================
# Main Module - CrowdStrike GCP CSPM Registration
# =============================================================================

module "crowdstrike_gcp_registration" {
  source = "../.."
  # TODO: Update to tagged version after v0.1.0-alpha release
  # source = "git::https://github.com/CrowdStrike/terraform-google-cloud-registration.git?ref=v0.1.0-alpha"

  # =============================================================================
  # Core Configuration
  # =============================================================================

  # GCP Infrastructure Project
  infra_project_id = var.infra_project_id

  # AWS Integration (CrowdStrike Role ARN)
  role_arn = var.role_arn

  # Workload Identity Federation Configuration
  wif_pool_id          = var.wif_pool_id
  wif_pool_provider_id = var.wif_pool_provider_id

  # =============================================================================
  # Registration Scope - Project Level
  # =============================================================================

  registration_type = "project"
  registration_id   = var.registration_id
  project_ids       = var.project_ids

  # =============================================================================
  # Optional Features
  # =============================================================================

  # Real Time Visibility & Detection
  enable_realtime_visibility = var.enable_realtime_visibility

  # Log ingestion configuration
  log_ingestion_settings = {
    message_retention_duration       = var.log_retention_duration
    ack_deadline_seconds             = var.log_ack_deadline
    topic_message_retention_duration = var.topic_retention_duration
    audit_log_types                  = var.audit_log_types
    enable_schema_validation         = false
    schema_type                      = "AVRO"
    exclusion_filters                = var.log_exclusion_filters
  }

  # =============================================================================
  # Resource Naming
  # =============================================================================

  resource_prefix = var.resource_prefix
  resource_suffix = var.resource_suffix

  # =============================================================================
  # Tagging
  # =============================================================================

  labels = merge(var.labels, {
    managed-by  = "infrastructure-manager"
    module      = "crowdstrike-csmp"
    environment = var.environment
  })
}
