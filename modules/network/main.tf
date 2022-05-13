terraform {
    required_version = ">=1.1.3"
}

resource "google_compute_network" "az-network" {
  project                 = var.project
  name                    = var.network_name //"az-network"
  auto_create_subnetworks = false
}