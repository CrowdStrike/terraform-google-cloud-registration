module "workload-identity" {
  source = "./modules/workload-identity/"
  wif_project_id = var.wif_project_id
  wif_pool_id = var.wif_pool_id
  wif_pool_provider_id = var.wif_pool_provider_id
  wif_pool_provider_name = var.wif_pool_provider_name
  wif_pool_name = var.wif_pool_name
  aws_account_id=var.aws_account_id
}