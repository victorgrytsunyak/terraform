terraform {
    required_version = ">=1.1.3"
}

resource "google_compute_firewall" "rules" {
  name          = var.firewall_name //"allow-ssh"
  network       = var.network//"az-network"
  source_ranges = var.ip_source_ranges  //["194.44.223.172/30"]


  allow {
    ports    = var.firewall_ports //["22"]
    protocol = var.firewall_protocol //"tcp"
  }
  target_tags = var.tags //["ssh"]
}