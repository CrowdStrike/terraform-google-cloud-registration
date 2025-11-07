module "workload-identity" {
  source               = "./modules/workload-identity/"
  wif_project_id       = var.wif_project_id
  wif_pool_id          = var.wif_pool_id
  wif_pool_provider_id = var.wif_pool_provider_id
  aws_account_id       = var.aws_account_id
  role_arn             = var.role_arn
  registration_id      = var.registration_id
  resource_prefix      = var.resource_prefix
  resource_suffix      = var.resource_suffix
}

module "log-ingestion" {
  count  = var.enable_realtime_visibility ? 1 : 0
  source = "./modules/log-ingestion/"

  # Required parameters
  wif_iam_principal            = module.workload-identity.wif_iam_principal
  registration_type            = var.registration_type
  registration_id              = var.registration_id
  organization_id              = var.organization_id
  folder_ids                   = var.folder_ids
  project_ids                  = var.project_ids
  crowdstrike_infra_project_id = var.wif_project_id
  resource_prefix              = var.resource_prefix
  resource_suffix              = var.resource_suffix
  labels                       = var.labels

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