output "pubsub_topic_id" {
  description = "The generated ID of the Google Cloud pub/sub topic"
  value       = local.create_topic ? google_pubsub_topic.crowdstrike_logs[0].id : data.google_pubsub_topic.existing_crowdstrike_logs[0].id
}

output "pubsub_topic_name" {
  description = "The name of the Google Cloud pub/sub topic"
  value       = local.create_topic ? google_pubsub_topic.crowdstrike_logs[0].name : data.google_pubsub_topic.existing_crowdstrike_logs[0].name
}

output "subscription_id" {
  description = "The subscription that will be used to ingest data from the Google Cloud Pub/Sub topic"
  value       = local.create_subscription ? google_pubsub_subscription.crowdstrike_logs[0].id : data.google_pubsub_subscription.existing_crowdstrike_logs[0].id
}

output "subscription_name" {
  description = "The name of the Google Cloud pub/sub subscription"
  value       = local.create_subscription ? google_pubsub_subscription.crowdstrike_logs[0].name : data.google_pubsub_subscription.existing_crowdstrike_logs[0].name
}

output "log_sink_names" {
  description = "Names of the created log router sinks"
  value = merge(
    var.registration_type == "organization" ? {
      organization = google_logging_organization_sink.crowdstrike_logs[0].name
    } : {},
    var.registration_type == "folder" ? {
      for folder_id in keys(google_logging_folder_sink.crowdstrike_logs) : folder_id => google_logging_folder_sink.crowdstrike_logs[folder_id].name
    } : {},
    var.registration_type == "project" ? {
      for project_id in keys(google_logging_project_sink.crowdstrike_logs) : project_id => google_logging_project_sink.crowdstrike_logs[project_id].name
    } : {}
  )
}

output "log_sink_writer_identities" {
  description = "Writer identities for the created log router sinks"
  value = merge(
    var.registration_type == "organization" ? {
      organization = google_logging_organization_sink.crowdstrike_logs[0].writer_identity
    } : {},
    var.registration_type == "folder" ? {
      for folder_id in keys(google_logging_folder_sink.crowdstrike_logs) : folder_id => google_logging_folder_sink.crowdstrike_logs[folder_id].writer_identity
    } : {},
    var.registration_type == "project" ? {
      for project_id in keys(google_logging_project_sink.crowdstrike_logs) : project_id => google_logging_project_sink.crowdstrike_logs[project_id].writer_identity
    } : {}
  )
}

output "log_ingestion_project_id" {
  description = "Project ID where log ingestion resources are deployed"
  value       = var.infra_project_id
}

output "log_filter" {
  description = "The log filter used by the log router sinks"
  value       = local.combined_filter
}

output "apis_enabled" {
  description = "List of Google Cloud APIs enabled for log ingestion"
  value       = keys(google_project_service.log_ingestion_apis)
}
