# Send the final tegistration settings back to Falcon API
resource "null_resource" "crowdstrike_settings_update" {
  provisioner "local-exec" {
    command = var.customer_id != null && var.customer_id != "" ? "${path.module}/settings-update-internal.sh" : "${path.module}/settings-update.sh"
    
    environment = {
      FALCON_CLIENT_ID      = var.falcon_client_id
      FALCON_CLIENT_SECRET  = var.falcon_client_secret
      FALCON_API_HOST       = var.falcon_api_host
      FALCON_CLOUD_API_HOST = var.falcon_cloud_api_host
      CUSTOMER_ID           = var.customer_id
      REGISTRATION_ID       = var.registration_id
      WIF_POOL_ID           = var.wif_pool_id
      WIF_PROJECT_NUMBER    = var.wif_project_number
      WIF_PROJECT_ID        = var.wif_project_id
      WIF_PROVIDER_ID       = var.wif_provider_id
      LOG_TOPIC_ID          = var.log_topic_id
      LOG_SUBSCRIPTION_ID   = var.log_subscription_id
      LOG_SINK_NAME         = var.log_sink_name
    }
  }

  depends_on = [var.completion_trigger]
}