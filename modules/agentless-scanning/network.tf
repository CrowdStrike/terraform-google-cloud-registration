# =============================================================================
# VPC Network (Managed Mode Only, per host project)
# =============================================================================

resource "google_compute_network" "agentless_vpc" {
  for_each = local.is_custom_vpc ? toset([]) : toset(local.host_project_ids)

  project                 = each.value
  name                    = "${var.resource_prefix}agentless-vpc${var.resource_suffix}"
  auto_create_subnetworks = false

  depends_on = [google_project_service.required_apis]
}

resource "google_compute_subnetwork" "agentless_subnet" {
  for_each = local.project_region_pairs

  project       = each.value.project
  name          = "${var.resource_prefix}agentless-subnet-${each.value.region}${var.resource_suffix}"
  ip_cidr_range = "10.0.${index(local.sorted_regions, each.value.region)}.0/24"
  region        = each.value.region
  network       = google_compute_network.agentless_vpc[each.value.project].id

  private_ip_google_access = true
}

# =============================================================================
# Subnet-Level IAM - Network User (Managed VPC)
# =============================================================================

resource "google_compute_subnetwork_iam_member" "wif_subnet_network_user" {
  for_each = local.project_region_pairs

  project    = each.value.project
  region     = each.value.region
  subnetwork = google_compute_subnetwork.agentless_subnet[each.key].name
  role       = "roles/compute.networkUser"
  member     = local.agentless_wif_principal
}

# =============================================================================
# Subnet-Level IAM - Network User (Custom VPC)
# =============================================================================

# Validate each provided subnet actually belongs to the named VPC. Fails fast at plan/apply.
data "google_compute_subnetwork" "byo_validation" {
  for_each = local.custom_vpc_subnet_pairs

  project = each.value.project
  region  = each.value.region
  name    = each.value.subnetwork

  lifecycle {
    postcondition {
      condition     = endswith(self.network, "/networks/${var.custom_vpc_configuration.vpc_name}")
      error_message = "Subnet '${each.value.subnetwork}' (region '${each.value.region}') does not belong to VPC '${var.custom_vpc_configuration.vpc_name}'."
    }
  }
}

resource "google_compute_subnetwork_iam_member" "wif_byo_subnet_network_user" {
  for_each = local.custom_vpc_subnet_pairs

  project    = each.value.project
  region     = each.value.region
  subnetwork = each.value.subnetwork
  role       = "roles/compute.networkUser"
  member     = local.agentless_wif_principal

  depends_on = [data.google_compute_subnetwork.byo_validation]
}

# =============================================================================
# Cloud Router + NAT (Managed VPC Only, Optional)
# =============================================================================

resource "google_compute_router" "agentless_router" {
  for_each = local.project_region_nat_pairs

  project = each.value.project
  name    = "${var.resource_prefix}agentless-router-${each.value.region}${var.resource_suffix}"
  region  = each.value.region
  network = google_compute_network.agentless_vpc[each.value.project].id
}

resource "google_compute_router_nat" "agentless_nat" {
  for_each = local.project_region_nat_pairs

  project                            = each.value.project
  name                               = "${var.resource_prefix}agentless-nat-${each.value.region}${var.resource_suffix}"
  router                             = google_compute_router.agentless_router[each.key].name
  region                             = each.value.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
