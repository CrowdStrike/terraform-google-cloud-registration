locals {
  effective_wif_project_id = var.wif_project_id != null ? var.wif_project_id : var.infra_project_id
  effective_prefix         = var.resource_prefix != null ? var.resource_prefix : ""
  effective_suffix         = var.resource_suffix != null ? var.resource_suffix : ""
}

# Data source to get WIF project information
data "google_project" "wif_project" {
  provider   = google.wif
  project_id = local.effective_wif_project_id
}

# CrowdStrike GCP registration resource
resource "crowdstrike_cloud_google_registration" "main" {
  name              = var.registration_name
  infra_project     = var.infra_project_id
  wif_project       = local.effective_wif_project_id
  deployment_method = var.deployment_method

  # Set the appropriate registration scope
  projects     = var.registration_type == "project" ? var.project_ids : null
  folders      = var.registration_type == "folder" ? var.folder_ids : null
  organization = var.registration_type == "organization" ? var.organization_id : null

  # Resource naming
  resource_name_prefix = var.resource_prefix != "" ? var.resource_prefix : null
  resource_name_suffix = var.resource_suffix != "" ? var.resource_suffix : null

  # Labels from variables
  labels = var.labels

  # Enable realtime visibility if requested
  realtime_visibility = {
    enabled = var.enable_realtime_visibility
  }
}

module "workload-identity" {
  source               = "./modules/workload-identity/"
  wif_project_id       = local.effective_wif_project_id
  wif_pool_id          = crowdstrike_cloud_google_registration.main.wif_pool_id
  wif_pool_provider_id = crowdstrike_cloud_google_registration.main.wif_provider_id
  role_arn             = var.role_arn
  registration_id      = crowdstrike_cloud_google_registration.main.id
  resource_prefix      = local.effective_prefix
  resource_suffix      = local.effective_suffix

  providers = {
    google = google.wif
  }
}
module "project-discovery" {
  source = "./modules/project-discovery/"

  registration_type = var.registration_type
  organization_id   = var.organization_id
  folder_ids        = var.folder_ids
  project_ids       = var.project_ids
}

module "asset-inventory" {
  source = "./modules/asset-inventory/"

  wif_iam_principal   = module.workload-identity.wif_iam_principal
  registration_type   = var.registration_type
  organization_id     = var.organization_id
  folder_ids          = var.folder_ids
  discovered_projects = module.project-discovery.discovered_projects

  depends_on = [module.workload-identity, module.project-discovery]
}

module "log-ingestion" {
  count  = var.enable_realtime_visibility ? 1 : 0
  source = "./modules/log-ingestion/"

  # Required parameters
  wif_iam_principal = module.workload-identity.wif_iam_principal
  registration_type = var.registration_type
  registration_id   = crowdstrike_cloud_google_registration.main.id
  organization_id   = var.organization_id
  folder_ids        = var.folder_ids
  project_ids       = var.project_ids
  infra_project_id  = var.infra_project_id
  resource_prefix   = local.effective_prefix
  resource_suffix   = local.effective_suffix
  labels            = var.labels

  # Optional settings - structured configuration, child module handles defaults
  message_retention_duration       = var.log_ingestion_settings.message_retention_duration
  ack_deadline_seconds             = var.log_ingestion_settings.ack_deadline_seconds
  topic_message_retention_duration = var.log_ingestion_settings.topic_message_retention_duration
  audit_log_types                  = var.log_ingestion_settings.audit_log_types
  topic_storage_regions            = var.log_ingestion_settings.topic_storage_regions
  enable_schema_validation         = var.log_ingestion_settings.enable_schema_validation
  schema_type                      = var.log_ingestion_settings.schema_type
  schema_definition                = var.log_ingestion_settings.schema_definition
  existing_topic_name              = var.log_ingestion_settings.existing_topic_name
  existing_subscription_name       = var.log_ingestion_settings.existing_subscription_name
  exclusion_filters                = var.log_ingestion_settings.exclusion_filters

  depends_on = [module.workload-identity]
}

# CrowdStrike logging settings for realtime visibility
resource "crowdstrike_cloud_google_registration_logging_settings" "main" {
  registration_id                 = crowdstrike_cloud_google_registration.main.id
  wif_project                     = local.effective_wif_project_id
  wif_project_number              = data.google_project.wif_project.number
  log_ingestion_topic_id          = try(module.log-ingestion[0].pubsub_topic_name, null)
  log_ingestion_subscription_name = try(module.log-ingestion[0].subscription_name, null)
  log_ingestion_sink_name         = try(values(module.log-ingestion[0].log_sink_names)[0], null)

  depends_on = [
    crowdstrike_cloud_google_registration.main,
    module.workload-identity,
    module.asset-inventory,
    module.log-ingestion,
    module.project-discovery
  ]
}
