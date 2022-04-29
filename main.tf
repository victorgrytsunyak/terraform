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
## Module for installing VMs
module "vms" {
  source = "./modules/instances"
  for_each = {

    "vm1" = { machine_type = "g1-small", image_vm = "centos-cloud/centos-7", startup_script = file("script.sh"), metadata = {
      enable-oslogin         = false
      block-project-ssh-keys = true
      ssh-keys               = <<EOT
    admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbi+rm7By+HYqpS0Uy5FMmGD50Mf7hoW6iHIVru28W4/MZAK9XmZXzI1KKDA/eS4g0E5XScue/is3329VGBEljn6ZCO/FO6xEhTv4UEklPIGJDWa89/IuX39KE/7uI0wQ+Fjj35YEhbe8z9cmWrBbba0Z7zQDZpAxKVEU3+R5MHc+O1Ctm6PbAdtIsDGjHx3zYyBp3tT9SJbxIp2m1DNEa1BMkNXb2EBbR8V8eCHKxxkOhgv06I//xkQGIB9vySv1AXwEixg4iW93eeMnzg0dYSeCvt+PhStpGnekqfRow74LWfwDo7FwP2A0Ycmc1KKLOZk9N8kR6ghzBiJ5KYdOoYoL4ezNyD0kZjrfmP/QRaOxhrrvFsJ8LOnLQps6RQyDIOteZ4GYfr+1zG8AfQF0ZMVVUketNFsQ2hpMms9rVWE0NAis4evoGo6s6RoqElgrWrd3PYKb8t0+dmFa3kHXLHD84mn4sgnt8dqbuayW/hljGzELYmK1byd/JcONgLRc= admin@DESKTOP-9EEH9LJ
    EOT
      }
    }

    "vm2" = { machine_type = "f1-micro", image_vm = "ubuntu-os-cloud/ubuntu-2004-lts", startup_script = file("startup.sh"), metadata = {
      enable-oslogin         = false
      block-project-ssh-keys = true
      ssh-keys               = <<EOT
    root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbi+rm7By+HYqpS0Uy5FMmGD50Mf7hoW6iHIVru28W4/MZAK9XmZXzI1KKDA/eS4g0E5XScue/is3329VGBEljn6ZCO/FO6xEhTv4UEklPIGJDWa89/IuX39KE/7uI0wQ+Fjj35YEhbe8z9cmWrBbba0Z7zQDZpAxKVEU3+R5MHc+O1Ctm6PbAdtIsDGjHx3zYyBp3tT9SJbxIp2m1DNEa1BMkNXb2EBbR8V8eCHKxxkOhgv06I//xkQGIB9vySv1AXwEixg4iW93eeMnzg0dYSeCvt+PhStpGnekqfRow74LWfwDo7FwP2A0Ycmc1KKLOZk9N8kR6ghzBiJ5KYdOoYoL4ezNyD0kZjrfmP/QRaOxhrrvFsJ8LOnLQps6RQyDIOteZ4GYfr+1zG8AfQF0ZMVVUketNFsQ2hpMms9rVWE0NAis4evoGo6s6RoqElgrWrd3PYKb8t0+dmFa3kHXLHD84mn4sgnt8dqbuayW/hljGzELYmK1byd/JcONgLRc= admin@DESKTOP-9EEH9LJ
    EOT
      }
    }
  }

  subnetwork     = var.subnet
  ip_range       = var.ip
  tags           = var.tags
  machine_type   = each.value.machine_type
  vm_name        = each.key
  image_vm       = each.value.image_vm
  startup_script = each.value.startup_script
  metadata       = each.value.metadata
  email          = var.sa_email
  scope          = []
  depends_on = [
    google_compute_subnetwork.az-subnet
  ]
}

module "vms_count" {
  source         = "./modules/instances" 
  count = 2
  subnetwork     = var.subnet // "az-subnet"
  ip_range       = var.ip     //"10.10.10.0/24"
  tags           = var.tags   //["web", "ssh"]
  vm_name        = "instance${count.index}"
  machine_type   = var.vm_type //"g1-small"
  image_vm       = "centos-cloud/centos-7"
  startup_script = file("script.sh")
  metadata       = {
      enable-oslogin         = false
      block-project-ssh-keys = true
      ssh-keys             = <<EOT
    admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbi+rm7By+HYqpS0Uy5FMmGD50Mf7hoW6iHIVru28W4/MZAK9XmZXzI1KKDA/eS4g0E5XScue/is3329VGBEljn6ZCO/FO6xEhTv4UEklPIGJDWa89/IuX39KE/7uI0wQ+Fjj35YEhbe8z9cmWrBbba0Z7zQDZpAxKVEU3+R5MHc+O1Ctm6PbAdtIsDGjHx3zYyBp3tT9SJbxIp2m1DNEa1BMkNXb2EBbR8V8eCHKxxkOhgv06I//xkQGIB9vySv1AXwEixg4iW93eeMnzg0dYSeCvt+PhStpGnekqfRow74LWfwDo7FwP2A0Ycmc1KKLOZk9N8kR6ghzBiJ5KYdOoYoL4ezNyD0kZjrfmP/QRaOxhrrvFsJ8LOnLQps6RQyDIOteZ4GYfr+1zG8AfQF0ZMVVUketNFsQ2hpMms9rVWE0NAis4evoGo6s6RoqElgrWrd3PYKb8t0+dmFa3kHXLHD84mn4sgnt8dqbuayW/hljGzELYmK1byd/JcONgLRc= admin@DESKTOP-9EEH9LJ
    EOT
      }
  email          = var.sa_email
  scope          = []
  depends_on = [
    google_compute_subnetwork.az-subnet
  ]
}

//module "vm2" {
// source         = "./modules/instances"
// subnetwork     = var.subnet // "az-subnet"
// ip_range       = var.ip     //"10.10.10.0/24"
// tags           = var.tags   //["web", "ssh"]
// vm_name        = "vm2"
// machine_type   = var.vm_type //"g1-small"
// image_vm       = "ubuntu-os-cloud/ubuntu-2004-lts"
// startup_script = file("startup.sh")
// metadata       = var.ssh_key_ub
// email          = var.sa_email
//  scope          = []
//  depends_on = [
//   google_compute_subnetwork.az-subnet
// ]
//}