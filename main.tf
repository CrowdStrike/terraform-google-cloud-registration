module "workload-identity" {
  source               = "./modules/workload-identity/"
  wif_project_id       = var.wif_project_id
  wif_pool_id          = var.wif_pool_id
  wif_pool_provider_id = var.wif_pool_provider_id
  aws_account_id       = var.aws_account_id
  resource_prefix      = var.resource_prefix
  resource_suffix      = var.resource_suffix
}