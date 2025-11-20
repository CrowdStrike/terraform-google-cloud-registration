locals {
  folder_list  = var.folder_ids
  project_list = var.project_ids

  # Generate resource names with prefix/suffix or use existing names
  topic_name        = var.existing_topic_name != "" ? var.existing_topic_name : "${var.resource_prefix}CrowdStrikeLogTopic-${var.registration_id}${var.resource_suffix}"
  subscription_name = var.existing_subscription_name != "" ? var.existing_subscription_name : "${var.resource_prefix}CrowdStrikeLogSubscription-${var.registration_id}${var.resource_suffix}"
  sink_name         = "${var.resource_prefix}CrowdStrikeLogSink${var.resource_suffix}"

  # Determine if creating new resources
  create_topic        = var.existing_topic_name == ""
  create_subscription = var.existing_subscription_name == ""

  # Build log filter for specific audit log types
  log_filter = "protoPayload.@type=\"type.googleapis.com/google.cloud.audit.AuditLog\" AND (${join(" OR ", [
    for log_type in var.audit_log_types : "logName:\"cloudaudit.googleapis.com/${log_type}\""
  ])})"

  # Build inclusion filter based on registration type
  inclusion_filter = var.registration_type == "organization" ? "resource.labels.organization_id=\"${var.organization_id}\"" : (
    var.registration_type == "folder" ? "protoPayload.resourceName=~\"(${join("|", [
      for folder_id in local.folder_list : "folders/${trimspace(folder_id)}"
    ])})/\"" : join(" OR ", [
      for project_id in local.project_list : "resource.labels.project_id=\"${trimspace(project_id)}\""
    ])
  )

  # Build exclusion filter if provided
  exclusion_filter = length(var.exclusion_filters) > 0 ? join(" AND ", [
    for filter in var.exclusion_filters : "NOT (${filter})"
  ]) : ""

  # Combined filter with optional exclusions
  combined_filter = length(var.exclusion_filters) > 0 ? "(${local.log_filter}) AND (${local.inclusion_filter}) AND (${local.exclusion_filter})" : "(${local.log_filter}) AND (${local.inclusion_filter})"
}

# Enable required APIs for log ingestion
resource "google_project_service" "log_ingestion_apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "pubsub.googleapis.com",
    "monitoring.googleapis.com",
    "serviceusage.googleapis.com"
  ])

  project                    = var.infra_project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = true
}

# Create Pub/Sub Schema (optional)
resource "google_pubsub_schema" "crowdstrike_logs" {
  count = var.enable_schema_validation && local.create_topic ? 1 : 0

  name       = "${var.resource_prefix}CrowdStrikeLogSchema${var.resource_suffix}"
  project    = var.infra_project_id
  type       = var.schema_type
  definition = var.schema_definition

  depends_on = [google_project_service.log_ingestion_apis]
}

# Create Pub/Sub Topic for audit logs (only if not using existing)
resource "google_pubsub_topic" "crowdstrike_logs" {
  count = local.create_topic ? 1 : 0

  name    = local.topic_name
  project = var.infra_project_id

  # Configure message retention
  message_retention_duration = var.topic_message_retention_duration

  # Configure message storage regions
  dynamic "message_storage_policy" {
    for_each = length(var.topic_storage_regions) > 0 ? [1] : []
    content {
      allowed_persistence_regions = var.topic_storage_regions
    }
  }

  # Configure schema validation
  dynamic "schema_settings" {
    for_each = var.enable_schema_validation ? [1] : []
    content {
      schema   = google_pubsub_schema.crowdstrike_logs[0].id
      encoding = "JSON"
    }
  }

  labels = var.labels

  depends_on = [google_project_service.log_ingestion_apis]
}

# Data source for existing topic (if using existing)
data "google_pubsub_topic" "existing_crowdstrike_logs" {
  count = local.create_topic ? 0 : 1

  name    = local.topic_name
  project = var.infra_project_id
}

# Create Pub/Sub Subscription (only if not using existing)
resource "google_pubsub_subscription" "crowdstrike_logs" {
  count = local.create_subscription ? 1 : 0

  name    = local.subscription_name
  topic   = local.create_topic ? google_pubsub_topic.crowdstrike_logs[0].name : data.google_pubsub_topic.existing_crowdstrike_logs[0].name
  project = var.infra_project_id

  message_retention_duration = var.message_retention_duration
  ack_deadline_seconds       = var.ack_deadline_seconds

  enable_exactly_once_delivery = true

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  expiration_policy {
    ttl = ""
  }

  labels = var.labels

  depends_on = [google_pubsub_topic.crowdstrike_logs, data.google_pubsub_topic.existing_crowdstrike_logs]
}

# Data source for existing subscription (if using existing)
data "google_pubsub_subscription" "existing_crowdstrike_logs" {
  count = local.create_subscription ? 0 : 1

  name    = local.subscription_name
  project = var.infra_project_id
}

# Create log router sink for organization-level registration
resource "google_logging_organization_sink" "crowdstrike_logs" {
  count = var.registration_type == "organization" ? 1 : 0

  name             = local.sink_name
  org_id           = var.organization_id
  destination      = local.create_topic ? "pubsub.googleapis.com/${google_pubsub_topic.crowdstrike_logs[0].id}" : "pubsub.googleapis.com/${data.google_pubsub_topic.existing_crowdstrike_logs[0].id}"
  filter           = local.combined_filter
  include_children = true

  depends_on = [google_pubsub_topic.crowdstrike_logs, data.google_pubsub_topic.existing_crowdstrike_logs]
}

# Create log router sink for folder-level registration
resource "google_logging_folder_sink" "crowdstrike_logs" {
  for_each = toset(var.registration_type == "folder" ? local.folder_list : [])

  name             = "${local.sink_name}-${trimspace(each.key)}"
  folder           = trimspace(each.key)
  destination      = local.create_topic ? "pubsub.googleapis.com/${google_pubsub_topic.crowdstrike_logs[0].id}" : "pubsub.googleapis.com/${data.google_pubsub_topic.existing_crowdstrike_logs[0].id}"
  filter           = local.combined_filter
  include_children = true

  depends_on = [google_pubsub_topic.crowdstrike_logs, data.google_pubsub_topic.existing_crowdstrike_logs]
}

# Create log router sink for project-level registration
resource "google_logging_project_sink" "crowdstrike_logs" {
  for_each = toset(var.registration_type == "project" ? local.project_list : [])

  name        = "${local.sink_name}-${trimspace(each.key)}"
  project     = trimspace(each.key)
  destination = local.create_topic ? "pubsub.googleapis.com/${google_pubsub_topic.crowdstrike_logs[0].id}" : "pubsub.googleapis.com/${data.google_pubsub_topic.existing_crowdstrike_logs[0].id}"
  filter      = local.combined_filter

  # Use unique writer identity
  unique_writer_identity = true

  depends_on = [google_pubsub_topic.crowdstrike_logs, data.google_pubsub_topic.existing_crowdstrike_logs]
}

# Grant Pub/Sub publisher role to log router service account (organization)
resource "google_pubsub_topic_iam_member" "log_writer_org" {
  count = var.registration_type == "organization" ? 1 : 0

  project = var.infra_project_id
  topic   = local.create_topic ? google_pubsub_topic.crowdstrike_logs[0].name : data.google_pubsub_topic.existing_crowdstrike_logs[0].name
  role    = "roles/pubsub.publisher"
  member  = google_logging_organization_sink.crowdstrike_logs[0].writer_identity

  depends_on = [google_logging_organization_sink.crowdstrike_logs]
}

# Grant Pub/Sub publisher role to log router service account (folders)
resource "google_pubsub_topic_iam_member" "log_writer_folder" {
  for_each = var.registration_type == "folder" ? toset(local.folder_list) : []

  project = var.infra_project_id
  topic   = local.create_topic ? google_pubsub_topic.crowdstrike_logs[0].name : data.google_pubsub_topic.existing_crowdstrike_logs[0].name
  role    = "roles/pubsub.publisher"
  member  = google_logging_folder_sink.crowdstrike_logs[each.key].writer_identity

  depends_on = [google_logging_folder_sink.crowdstrike_logs]
}

# Grant Pub/Sub publisher role to log router service account (projects)
resource "google_pubsub_topic_iam_member" "log_writer_project" {
  for_each = var.registration_type == "project" ? toset(local.project_list) : []

  project = var.infra_project_id
  topic   = local.create_topic ? google_pubsub_topic.crowdstrike_logs[0].name : data.google_pubsub_topic.existing_crowdstrike_logs[0].name
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.crowdstrike_logs[each.key].writer_identity

  depends_on = [google_logging_project_sink.crowdstrike_logs]
}

# Grant CrowdStrike principal access to Pub/Sub
resource "google_pubsub_subscription_iam_member" "crowdstrike_subscriber" {
  subscription = local.create_subscription ? google_pubsub_subscription.crowdstrike_logs[0].name : data.google_pubsub_subscription.existing_crowdstrike_logs[0].name
  project      = var.infra_project_id
  role         = "roles/pubsub.subscriber"
  member       = var.wif_iam_principal

  depends_on = [google_pubsub_subscription.crowdstrike_logs, data.google_pubsub_subscription.existing_crowdstrike_logs]
}

resource "google_pubsub_topic_iam_member" "crowdstrike_viewer" {
  topic   = local.create_topic ? google_pubsub_topic.crowdstrike_logs[0].name : data.google_pubsub_topic.existing_crowdstrike_logs[0].name
  project = var.infra_project_id
  role    = "roles/pubsub.viewer"
  member  = var.wif_iam_principal

  depends_on = [google_pubsub_topic.crowdstrike_logs, data.google_pubsub_topic.existing_crowdstrike_logs]
}

resource "google_project_iam_member" "crowdstrike_monitoring_viewer" {
  project = var.infra_project_id
  role    = "roles/monitoring.viewer"
  member  = var.wif_iam_principal
}