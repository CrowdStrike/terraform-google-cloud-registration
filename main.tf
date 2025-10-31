module "workload-identity" {
  source               = "./modules/workload-identity/"
  wif_project_id       = var.wif_project_id
  wif_pool_id          = var.wif_pool_id
  wif_pool_provider_id = var.wif_pool_provider_id
  aws_account_id       = var.aws_account_id
  registration_id      = var.registration_id
  resource_prefix      = var.resource_prefix
  resource_suffix      = var.resource_suffix
}

module "asset-inventory" {
  source = "./modules/asset-inventory/"

  wif_iam_principal = module.workload-identity.wif_iam_principal
  registration_type = var.registration_type
  organization_id   = var.organization_id
  folder_ids        = var.folder_ids
  project_ids       = var.project_ids

  depends_on = [module.workload-identity]
}
