terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.14.0"
    }
  }
}

resource "google_service_account" "SA" {
  account_id   = "azimuth"
  display_name = "azimuth"
  description  = "terraform_sa"
}
resource "google_service_account_key" "key" {
  service_account_id = "azimuth"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

provider "google" {
  project = "azimuth-80700"
  region  = "europe-west3"
  zone    = "europe-west3-b"
}

resource "google_compute_network" "az-network" {
  project                 = "azimuth-80700"
  name                    = "az-network"
  auto_create_subnetworks = false
  mtu                     = 1460 // investigate
}

resource "google_compute_subnetwork" "az-subnet" {
  name          = "az-subnet"
  ip_cidr_range = "10.10.10.0/24"
  region        = "europe-west3"
  network       = google_compute_network.az-network.id
}


// First virtual machine
resource "google_compute_instance" "vm_azimuth" {
  name         = "vm1"
  machine_type = "g1-small"
  tags         = ["ssh", "web"]
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }
  //Network config
  network_interface {
    subnetwork = google_compute_subnetwork.az-subnet.id
    access_config {
    }
  }
  // Adding ssh keys
  metadata = {
    enable-oslogin         = false
    block-project-ssh-keys = true
    "ssh-keys"             = <<EOT
    admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCdBNZcZ26lztFNd4d6plKF9dal321CQO0QnlLkWNo6fwCVk2tl0h35q7q6/groTROa//tYgIg3MIEDfdBXONj/fnQnYOvXFl3egwyHbkDAmmtrtGW2qr0f3AzPIaQw4nXxOys6lKvGCpgVJ+7r2BAweuc926ZFHyNuETkSOkotUJ6WHBhCgGj4uxuAU2/FSzIroWPgL3L3X0CxUSOV8ex4JpDK0TIDiB3Ed/WZZFdYZqty19jiwsC17SIVSSabUTXCGzFTKqFvYDY3q7YGwEfQnnOLNHMLqwaq/3fxoCXx75z+GkrOIxQIG1nYHU8D1ppAn+TpM92gICmKPJ/iJJj4pp8B21SzMK6S+PE7IJWZ37FrqhJdMgavIsukjsa7qm9jp6U4a46pihZEBwjM284EBXIN9496AUEkcC+5vTbi1Uzr80QdPf3XmKkC+2a/8P7eHSPT7qhO1unz92No6OJ2NnU46j4o2fxjOzHVOGyo7BRyyMW1f+UDtbKubI9xp3U= admin
    EOT
  }
  metadata_startup_script = file("script.sh")
}

//Second virtual machine
resource "google_compute_instance" "vm_ubuntu" {
  name         = "vm2"
  machine_type = "g1-small"
  tags         = ["ssh", "web"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.az-subnet.id
    access_config {

    }
  }
  metadata = {
    enable-oslogin         = false
    block-project-ssh-keys = true
   "ssh-keys"             = <<EOT
    root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCdBNZcZ26lztFNd4d6plKF9dal321CQO0QnlLkWNo6fwCVk2tl0h35q7q6/groTROa//tYgIg3MIEDfdBXONj/fnQnYOvXFl3egwyHbkDAmmtrtGW2qr0f3AzPIaQw4nXxOys6lKvGCpgVJ+7r2BAweuc926ZFHyNuETkSOkotUJ6WHBhCgGj4uxuAU2/FSzIroWPgL3L3X0CxUSOV8ex4JpDK0TIDiB3Ed/WZZFdYZqty19jiwsC17SIVSSabUTXCGzFTKqFvYDY3q7YGwEfQnnOLNHMLqwaq/3fxoCXx75z+GkrOIxQIG1nYHU8D1ppAn+TpM92gICmKPJ/iJJj4pp8B21SzMK6S+PE7IJWZ37FrqhJdMgavIsukjsa7qm9jp6U4a46pihZEBwjM284EBXIN9496AUEkcC+5vTbi1Uzr80QdPf3XmKkC+2a/8P7eHSPT7qhO1unz92No6OJ2NnU46j4o2fxjOzHVOGyo7BRyyMW1f+UDtbKubI9xp3U= admin
    EOT
  }
  metadata_startup_script = file("startup.sh")
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
}
resource "google_storage_bucket" "azimuth-bucket-store" {
  name          = "azimuth-vr-bucket"
  location      = "EU"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
}