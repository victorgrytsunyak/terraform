terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.14.0"
    }
  }
}

provider "google" {
  project = "azimuth-80700"
  region  = "europe-west3"
  zone    = "europe-west3-b"
}

resource "google_service_account" "SA" {
  project      = "azimuth-80700"
  account_id   = "azimuth"
  display_name = "azimuth"
  description  = "terraform_sa"
}

module "vms" {
  source        = "./modules/instances"
  project       = "azimuth-80700"
  region        = "europe-west3"
  zone          = "europe-west3-b"
  machine_type  = "g1-small"
  ip_cidr_range = "10.10.10.0/24"
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