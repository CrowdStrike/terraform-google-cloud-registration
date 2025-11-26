# =============================================================================
# CrowdStrike GCP CSPM Universal Registration Example
# =============================================================================
# This example demonstrates universal registration using the CrowdStrike
# GCP CSPM Terraform module. Works for project, folder, and organization
# level registration. Designed for deployment via GCP Infrastructure Manager.
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
    crowdstrike = {
      source = "crowdstrike/crowdstrike"
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

provider "crowdstrike" {
  client_id     = var.falcon_client_id
  client_secret = var.falcon_client_secret
}

# =============================================================================
# Locals for configuration
# =============================================================================

locals {
  effective_wif_project_id = var.wif_project_id != "" ? var.wif_project_id : var.infra_project_id
}

# =============================================================================
# CrowdStrike GCP Registration
# =============================================================================

resource "crowdstrike_cloud_google_registration" "main" {
  name              = "${var.resource_prefix}gcp-registration${var.resource_suffix}"
  projects          = var.registration_type == "project" ? var.project_ids : null
  folders           = var.registration_type == "folder" ? var.folder_ids : null
  organization      = var.registration_type == "organization" ? var.organization_id : null
  infra_project     = var.infra_project_id
  wif_project       = local.effective_wif_project_id
  deployment_method = "terraform-native"

  resource_name_prefix = var.resource_prefix != "" ? var.resource_prefix : null
  resource_name_suffix = var.resource_suffix != "" ? var.resource_suffix : null

  labels = var.labels

  # Enable realtime visibility if requested
  realtime_visibility = var.enable_realtime_visibility ? {
    enabled = true
  } : null
}

# =============================================================================
# Workload Identity, Asset Inventory, Log Ingestion
# =============================================================================

module "workload-identity" {
  source               = "../../modules/workload-identity/"
  wif_project_id       = local.effective_wif_project_id
  wif_pool_id          = crowdstrike_cloud_google_registration.main.wif_pool_id
  wif_pool_provider_id = crowdstrike_cloud_google_registration.main.wif_provider_id
  role_arn             = var.role_arn
  registration_id      = crowdstrike_cloud_google_registration.main.id
  resource_prefix      = var.resource_prefix
  resource_suffix      = var.resource_suffix
}

module "project-discovery" {
  source = "../../modules/project-discovery/"

  registration_type = var.registration_type
  organization_id   = var.organization_id
  folder_ids        = var.folder_ids
  project_ids       = var.project_ids
}

module "asset-inventory" {
  source = "../../modules/asset-inventory/"

  wif_iam_principal   = module.workload-identity.wif_iam_principal
  registration_type   = var.registration_type
  organization_id     = var.organization_id
  folder_ids          = var.folder_ids
  discovered_projects = module.project-discovery.discovered_projects

  depends_on = [module.workload-identity, module.project-discovery]
}

module "log-ingestion" {
  count  = var.enable_realtime_visibility ? 1 : 0
  source = "../../modules/log-ingestion/"

  wif_iam_principal = module.workload-identity.wif_iam_principal
  registration_type = var.registration_type
  registration_id   = crowdstrike_cloud_google_registration.main.id
  organization_id   = var.organization_id
  folder_ids        = var.folder_ids
  project_ids       = var.project_ids
  infra_project_id  = local.effective_wif_project_id
  resource_prefix   = var.resource_prefix
  resource_suffix   = var.resource_suffix
  labels            = var.labels

  message_retention_duration       = var.log_retention_duration
  ack_deadline_seconds             = var.log_ack_deadline
  topic_message_retention_duration = var.topic_retention_duration
  audit_log_types                  = var.audit_log_types
  enable_schema_validation         = false
  schema_type                      = "AVRO"
  exclusion_filters                = var.log_exclusion_filters

  depends_on = [module.workload-identity]
}

# =============================================================================
# CrowdStrike Registration Settings
# =============================================================================

resource "crowdstrike_cloud_google_registration_logging_settings" "main" {
  registration_id                 = crowdstrike_cloud_google_registration.main.id
  wif_project                     = local.effective_wif_project_id
  wif_project_number              = module.workload-identity.wif_project_number
  log_ingestion_topic_id          = var.enable_realtime_visibility ? module.log-ingestion[0].pubsub_topic_id : null
  log_ingestion_subscription_name = var.enable_realtime_visibility ? module.log-ingestion[0].subscription_id : null
  log_ingestion_sink_name         = var.enable_realtime_visibility ? values(module.log-ingestion[0].log_sink_names)[0] : null

  depends_on = [
    crowdstrike_cloud_google_registration.main,
    module.workload-identity,
    module.asset-inventory,
    module.log-ingestion
  ]
}