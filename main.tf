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

module "project-discovery" {
  source = "./modules/project-discovery/"

  registration_type = var.registration_type
  organization_id   = var.organization_id
  folder_ids        = var.folder_ids
  project_ids       = var.project_ids
}

module "asset-inventory" {
  source = "./modules/asset-inventory/"

  wif_iam_principal = module.workload-identity.wif_iam_principal
  registration_type = var.registration_type
  organization_id   = var.organization_id
  folder_ids        = var.folder_ids
  project_ids       = var.project_ids
  discovered_projects = module.project-discovery.discovered_projects

  depends_on = [module.workload-identity, module.project-discovery]
}
