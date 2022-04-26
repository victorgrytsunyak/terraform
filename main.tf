terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.14.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_service_account" "SA" {
  project      = var.project
  account_id   = "azimuth"
  display_name = "azimuth"
  description  = "terraform_sa"
}

resource "google_project_iam_member" "project_roles" {
  for_each = toset([
    "storage.objectAdmin"
  ])
  project = var.project
  role    = "roles/${each.key}"
  member  = "serviceAccount:azimuth@azimuthtv10-347408.iam.gserviceaccount.com"
}

resource "google_compute_network" "az-network" {
  project                 = var.project
  name                    = var.network_name //"az-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "az-subnet" {
  project       = var.project
  name          = var.subnet_name //"az-subnet"
  network       = google_compute_network.az-network.id
  ip_cidr_range = "10.10.10.0/24"

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
  depends_on = [
    google_compute_network.az-network
  ]
}

// Firewall set up
resource "google_compute_firewall" "ssh" {
  name          = "allow-ssh"
  network       = "az-network"
  source_ranges = ["194.44.223.172/30"]


  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  target_tags = ["ssh"]
  depends_on = [
    google_compute_network.az-network
  ]
}
resource "google_compute_firewall" "http-https" {
  name          = "allow-http"
  network       = "az-network"
  source_ranges = ["0.0.0.0/0"]


  allow {
    ports    = ["80", "443"]
    protocol = "tcp"
  }
  target_tags = ["web"]
  depends_on = [
    google_compute_network.az-network
  ]
}
resource "google_storage_bucket" "azimuth-bucket-store" {
  name                        = "azimuth-vr-bucket"
  location                    = "EU"
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
}

module "vm2" {
  source         = "./modules/instances"
  subnetwork     = var.subnet // "az-subnet"
  ip_range       = var.ip     //"10.10.10.0/24"
  tags           = var.tags   //["web", "ssh"]
  vm_name        = "vm1"
  machine_type   = var.vm_type //"g1-small"
  image_vm       = "centos-cloud/centos-7"
  startup_script = file("script.sh")
  metadata       = var.ssh_key_cen
  email          = var.sa_email
  scope          = []
  depends_on = [
    google_compute_subnetwork.az-subnet
  ]
}

module "vm2" {
  source         = "./modules/instances"
  subnetwork     = var.subnet // "az-subnet"
  ip_range       = var.ip     //"10.10.10.0/24"
  tags           = var.tags   //["web", "ssh"]
  vm_name        = "vm2"
  machine_type   = var.vm_type //"g1-small"
  image_vm       = "ubuntu-os-cloud/ubuntu-2004-lts"
  startup_script = file("startup.sh")
  metadata       = var.ssh_key_ub
  email          = var.sa_email
  scope          = []
  depends_on = [
    google_compute_subnetwork.az-subnet
  ]
}