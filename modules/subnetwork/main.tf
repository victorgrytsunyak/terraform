terraform {
    required_version = ">=1.1.3"
}

resource "google_compute_subnetwork" "az-subnet" {
  project       = var.project
  name          = var.subnet_name //"az-subnet"
  network       = var.network_name
  ip_cidr_range = var.ip_cidr_range
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.48.0.0/14"
  }
  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.52.0.0/20"
  }


  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}