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

# =============================================================================
# Provider Configuration
# =============================================================================

provider "google" {
  project = var.infra_project_id
}

provider "crowdstrike" {
  client_id     = var.falcon_client_id
  client_secret = var.falcon_client_secret
}

# =============================================================================
# Locals for configuration
# =============================================================================

locals {
  effective_wif_project_id = var.wif_project_id != null ? var.wif_project_id : var.infra_project_id
  network_configuration_type = (
    var.agentless_scanning_settings.custom_vpc_configuration != null ? "custom" :
    var.agentless_scanning_settings.deploy_cloud_nat ? "managed" : "managed_no_nat"
  )
}

# Data source to get WIF project information
data "google_project" "wif_project" {
  project_id = local.effective_wif_project_id
}

# =============================================================================
# CrowdStrike GCP Registration
# =============================================================================

resource "crowdstrike_cloud_google_registration" "main" {
  name               = var.registration_name
  projects           = var.registration_type == "project" ? var.project_ids : null
  folders            = var.registration_type == "folder" ? var.folder_ids : null
  organization       = var.registration_type == "organization" ? var.organization_id : null
  infra_project      = var.infra_project_id
  wif_project        = local.effective_wif_project_id
  wif_project_number = data.google_project.wif_project.number
  deployment_method  = var.deployment_method

  resource_name_prefix = var.resource_prefix != "" ? var.resource_prefix : null
  resource_name_suffix = var.resource_suffix != "" ? var.resource_suffix : null

  labels = var.labels

  excluded_project_patterns = var.excluded_project_patterns

  # Enable realtime visibility if requested
  realtime_visibility = var.enable_realtime_visibility ? {
    enabled = true
  } : null

  dspm = {
    enabled = var.enable_dspm
  }
}

# =============================================================================
# Workload Identity, Asset Inventory, Log Ingestion
# =============================================================================

locals {
  identity_source = crowdstrike_cloud_google_registration.main.identity_source

  wif_iam_principal = local.identity_source == "aws-sts" ? module.workload-identity[0].wif_iam_principal : module.workload-identity-oidc[0].wif_iam_principal
  wif_pool_name     = local.identity_source == "aws-sts" ? module.workload-identity[0].wif_pool_name : module.workload-identity-oidc[0].wif_pool_name
  wif_provider_name = local.identity_source == "aws-sts" ? module.workload-identity[0].wif_provider_name : module.workload-identity-oidc[0].wif_provider_name
}

module "workload-identity" {
  count                = local.identity_source == "aws-sts" ? 1 : 0
  source               = "../../modules/workload-identity/"
  wif_project_id       = local.effective_wif_project_id
  wif_pool_id          = crowdstrike_cloud_google_registration.main.wif_pool_id
  wif_pool_provider_id = crowdstrike_cloud_google_registration.main.wif_provider_id
  role_arn             = var.role_arn
  registration_id      = crowdstrike_cloud_google_registration.main.id
  resource_prefix      = var.resource_prefix
  resource_suffix      = var.resource_suffix
}

module "workload-identity-oidc" {
  count                     = local.identity_source == "gcp-oidc" ? 1 : 0
  source                    = "../../modules/workload-identity-oidc/"
  wif_project_id            = local.effective_wif_project_id
  wif_pool_id               = crowdstrike_cloud_google_registration.main.wif_pool_id
  wif_pool_provider_id      = crowdstrike_cloud_google_registration.main.wif_provider_id
  registration_id           = crowdstrike_cloud_google_registration.main.id
  service_account_unique_id = var.service_account_unique_id
  resource_prefix           = var.resource_prefix
  resource_suffix           = var.resource_suffix
}

module "asset-inventory" {
  source = "../../modules/asset-inventory/"

  wif_iam_principal = local.wif_iam_principal
  registration_type = var.registration_type
  organization_id   = var.organization_id
  folder_ids        = var.folder_ids
  project_ids       = var.project_ids
  wif_project_id    = local.effective_wif_project_id

  depends_on = [module.workload-identity, module.workload-identity-oidc]
}

module "log-ingestion" {
  count  = var.enable_realtime_visibility ? 1 : 0
  source = "../../modules/log-ingestion/"

  wif_iam_principal = local.wif_iam_principal
  registration_type = var.registration_type
  registration_id   = crowdstrike_cloud_google_registration.main.id
  organization_id   = var.organization_id
  folder_ids        = var.folder_ids
  project_ids       = var.project_ids
  infra_project_id  = var.infra_project_id
  wif_project_id    = local.effective_wif_project_id
  resource_prefix   = var.resource_prefix
  resource_suffix   = var.resource_suffix
  labels            = var.labels

  # Exclusion filters - combine log ingestion settings with project patterns
  # Convert shell-style wildcards to regex patterns for project exclusion
  # Examples: "sys-*" -> "^sys-.*$", "dev-?" -> "^dev-.$"
  exclusion_filters = concat(
    var.log_ingestion_settings.exclusion_filters,
    [for pattern in var.excluded_project_patterns : "resource.labels.project_id=~\"^${replace(replace(pattern, "*", ".*"), "?", ".")}$\""]
  )

  depends_on = [module.workload-identity, module.workload-identity-oidc]
}

module "agentless_scanning" {
  count  = var.enable_dspm ? 1 : 0
  source = "../../modules/agentless-scanning/"

  registration_type = var.registration_type
  registration_id   = crowdstrike_cloud_google_registration.main.id
  host_project_id   = var.agentless_scanning_settings.host_project_id
  project_ids       = var.project_ids
  organization_id   = var.organization_id
  folder_org_id     = var.agentless_scanning_settings.org_id
  folder_ids        = var.folder_ids
  labels            = var.labels
  resource_prefix   = var.resource_prefix
  resource_suffix   = var.resource_suffix

  wif_project_number                           = data.google_project.wif_project.number
  wif_pool_id                                  = local.identity_source == "aws-sts" ? module.workload-identity[0].wif_pool_id : module.workload-identity-oidc[0].wif_pool_id
  identity_source                              = local.identity_source
  agentless_scanning_role_arn                  = var.agentless_scanning_role_arn
  agentless_scanning_service_account_unique_id = var.agentless_scanning_service_account_unique_id

  falcon_client_id     = var.falcon_client_id
  falcon_client_secret = var.falcon_client_secret

  regions                  = var.agentless_scanning_settings.regions
  deploy_cloud_nat         = var.agentless_scanning_settings.deploy_cloud_nat
  custom_vpc_configuration = var.agentless_scanning_settings.custom_vpc_configuration

  depends_on = [module.workload-identity, module.workload-identity-oidc]
}

# =============================================================================
# CrowdStrike Registration Settings
# =============================================================================

resource "crowdstrike_cloud_google_registration_settings" "main" {
  registration_id                 = crowdstrike_cloud_google_registration.main.id
  wif_pool_name                   = local.wif_pool_name
  wif_provider_name               = local.wif_provider_name
  log_ingestion_topic_id          = try(module.log-ingestion[0].pubsub_topic_name, null)
  log_ingestion_subscription_name = try(module.log-ingestion[0].subscription_name, null)
  log_ingestion_sink_name         = try(values(module.log-ingestion[0].log_sink_names)[0], null)

  agentless_scanning_settings = var.enable_dspm ? {
    wif_principal              = module.agentless_scanning[0].agentless_wif_principal
    deployment_version         = module.agentless_scanning[0].deployment_version
    regions                    = var.agentless_scanning_settings.regions
    host_project_id            = var.agentless_scanning_settings.host_project_id
    org_id                     = var.registration_type == "folder" ? var.agentless_scanning_settings.org_id : null
    network_configuration_type = local.network_configuration_type

    custom_network = var.agentless_scanning_settings.custom_vpc_configuration != null ? {
      vpc_name = var.agentless_scanning_settings.custom_vpc_configuration.vpc_name
      subnets  = var.agentless_scanning_settings.custom_vpc_configuration.subnets
    } : null

    infra = module.agentless_scanning[0].agentless_infra
  } : null

  depends_on = [
    crowdstrike_cloud_google_registration.main,
    module.workload-identity,
    module.workload-identity-oidc,
    module.asset-inventory,
    module.log-ingestion,
    module.agentless_scanning
  ]
}
