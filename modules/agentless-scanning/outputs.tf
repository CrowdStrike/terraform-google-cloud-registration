output "agentless_wif_principal" {
  description = "WIF Principal string for agentless scanning IAM bindings"
  value       = local.agentless_wif_principal
}

output "scanner_sa_emails" {
  description = "Scanner Service Account emails per host project"
  value = {
    for project_id in local.host_project_ids :
    project_id => google_service_account.scanner_sa[project_id].email
  }
}

output "host_project_ids" {
  description = "GCP host project IDs (single project in cross mode, multiple in no-cross)"
  value       = local.host_project_ids
}

output "cross_target_ids" {
  description = "Target project IDs with cross-project GCS scanning permissions"
  value       = local.cross_target_ids
}

output "deployment_version" {
  description = "Module deployment version for BE tracking"
  value       = local.deployment_version
}

output "agentless_infra" {
  description = "Per-project infrastructure map for agentless scanning provider settings"
  value = {
    for project_id in local.host_project_ids :
    project_id => {
      scanner_sa_email               = google_service_account.scanner_sa[project_id].email
      client_credentials_secret_name = google_secret_manager_secret.falcon_credentials[project_id].secret_id
      network = {
        vpc_name = (local.is_custom_vpc
          ? var.custom_vpc_configuration.vpc_name
          : google_compute_network.agentless_vpc[project_id].name
        )
        subnets = (local.is_custom_vpc
          ? var.custom_vpc_configuration.subnets
          : {
            for region in var.regions :
            region => google_compute_subnetwork.agentless_subnet["${project_id}/${region}"].name
          }
        )
      }
    }
  }
}
