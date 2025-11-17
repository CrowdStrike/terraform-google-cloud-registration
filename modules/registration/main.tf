# CrowdStrike Registration Module
# Uses unified script to handle GCP registration CREATE and DELETE operations
resource "null_resource" "crowdstrike_registration" {
  provisioner "local-exec" {
    command = var.customer_id != null && var.customer_id != "" ? "${path.module}/registration_internal.sh" : "${path.module}/registration.sh"
    
    environment = {
      OPERATION                  = "CREATE"
      FALCON_CLIENT_ID           = var.falcon_client_id
      FALCON_CLIENT_SECRET       = var.falcon_client_secret
      FALCON_API_HOST            = var.falcon_api_host
      FALCON_CLOUD_API_HOST      = var.falcon_cloud_api_host
      CUSTOMER_ID                = var.customer_id
      ENABLE_REALTIME_VISIBILITY = var.enable_realtime_visibility
      REGISTRATION_NAME          = "${var.resource_prefix}gcp-registration${var.resource_suffix}"
      REGISTRATION_SCOPE         = var.registration_type
      ORGANIZATION_ID            = var.organization_id
      FOLDER_IDS                 = join(",", var.folder_ids)
      PROJECT_IDS                = join(",", var.project_ids)
      INFRA_PROJECT_ID           = var.infra_project_id
      WIF_PROJECT_ID             = var.wif_project_id
      RESOURCE_PREFIX            = var.resource_prefix
      RESOURCE_SUFFIX            = var.resource_suffix
      RANDOM_SUFFIX              = random_id.suffix.hex
    }
  }

  triggers = {
    parent_id             = local.parent_id
    wif_project_id        = var.wif_project_id
    falcon_client_id      = var.falcon_client_id
  }
}

# Separate resource for deletion that has access to registration_id
resource "null_resource" "crowdstrike_registration_delete" {
  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.customer_id != null && self.triggers.customer_id != "" ? "${path.module}/registration_internal.sh" : "${path.module}/registration.sh"
    
    environment = {
      OPERATION             = "DELETE"
      FALCON_CLIENT_ID      = self.triggers.falcon_client_id
      FALCON_CLIENT_SECRET  = self.triggers.falcon_client_secret
      FALCON_API_HOST       = self.triggers.falcon_api_host
      FALCON_CLOUD_API_HOST = self.triggers.falcon_cloud_api_host
      CUSTOMER_ID           = self.triggers.customer_id
      REGISTRATION_ID       = self.triggers.registration_id
    }
  }

  triggers = {
    registration_id       = data.local_file.registration_id.content
    falcon_client_id      = var.falcon_client_id
    falcon_client_secret  = var.falcon_client_secret
    falcon_api_host       = var.falcon_api_host
    falcon_cloud_api_host = var.falcon_cloud_api_host
    customer_id           = var.customer_id
  }

  depends_on = [null_resource.crowdstrike_registration]
}

resource "random_id" "suffix" {
  byte_length = 8
}

# Read the registration data from files created by script
data "local_file" "registration_id" {
  filename   = "/tmp/cs_registration_id_${random_id.suffix.hex}.txt"
  depends_on = [null_resource.crowdstrike_registration]
}

data "local_file" "wif_pool_id" {
  filename   = "/tmp/cs_wif_pool_id_${random_id.suffix.hex}.txt"
  depends_on = [null_resource.crowdstrike_registration]
}

data "local_file" "wif_provider_id" {
  filename   = "/tmp/cs_wif_provider_id_${random_id.suffix.hex}.txt"
  depends_on = [null_resource.crowdstrike_registration]
}

locals {
  parent_id = var.registration_type == "organization" ? var.organization_id : (
    var.registration_type == "folder" ? var.folder_ids[0] : var.project_ids[0]
  )
}