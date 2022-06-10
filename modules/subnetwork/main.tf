terraform {
    required_version = ">=1.1.3"
}

resource "google_compute_subnetwork" "az-subnet" {
  project       = var.project
  name          = var.subnet_name //"az-subnet"
  network       = var.network_name
  ip_cidr_range = var.ip_cidr_range
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}