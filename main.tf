terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.14.0"
    }
  }
}

provider "google" {
  project = "azimuthtv10-347408"
  region  = "europe-west3"
  zone    = "europe-west3-b"
}

resource "google_service_account" "SA" {
  project              = "azimuthtv10-347408"
  account_id           = "azimuth"
  display_name         = "azimuth"
  description          = "terraform_sa"
}

resource "google_service_account_iam_binding" "admin-account-iam" {
  service_account_id = google_service_account.SA.name
  role               = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:azimuth@azimuthtv10-347408.iam.gserviceaccount.com",
  ]
}

resource "google_project_iam_member" "project" {
  project = "azimuthtv10-347408"
  role    = "roles/owner"
  member  = "serviceAccount:azimuth@azimuthtv10-347408.iam.gserviceaccount.com"
}

resource "google_compute_network" "az-network" {
  project                 = "azimuthtv10-347408"
  name                    = "az-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "az-subnet" {
  project       = "azimuthtv10-347408"
  name          = "az-subnet"
  network       = google_compute_network.az-network.id
  ip_cidr_range = "10.10.10.0/24"

log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

// Firewall set up
resource "google_compute_firewall" "ssh" {
  name          = "allow-ssh"
  network       = "az-network"
  source_ranges = ["194.44.223.172/30"]


  allow {
    ports       = ["22"]
    protocol    = "tcp"
  }
  target_tags   = ["ssh"]
}
resource "google_compute_firewall" "http-https" {
  name          = "allow-http"
  network       = "az-network"
  source_ranges = ["0.0.0.0/0"]


  allow {
    ports        = ["80", "443"]
    protocol     = "tcp"
  }
  target_tags    = ["web"]
}
 resource "google_storage_bucket" "azimuth-bucket-store" {
  name           = "azimuth-vr-bucket"
  location       = "EU"
  force_destroy  = true
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

module "vms" {
  source          = "./modules/instances"
  project         = "azimuthtv10-347408"
  region          = "europe-west3"
  zone            = "europe-west3-b"
  subnetwork      = "az-subnet"
  ip_range        = "10.10.10.0/24"
  tags            = ["web", "ssh"]
  vm1_name        = "vm1"
  vm2_name        = "vm2"
  machine_type1   = "g1-small"
  machine_type2   = "g1-small"
  image_vm1       = "centos-cloud/centos-7"
  image_vm2       = "ubuntu-os-cloud/ubuntu-2004-lts"
}