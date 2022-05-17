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
    module.network
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
    module.network
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

#Module for creating network
module "network" {
  source       = "./modules/network"
  project      = var.project
  network_name = "az-network"
}

#module for creating subnetwork
module "subnetwork" {
  source        = "./modules/subnetwork"
  subnet_name   = "az-subnet"
  ip_cidr_range = "10.10.10.0/24"
  depends_on = [
    module.network
  ]
}

## Module for installing VMs
module "instances" {
  source = "./modules/instances"
  for_each = {

    "vm1" = { machine_type = "g1-small", image_vm = "centos-cloud/centos-7", startup_script = file("script.sh"), metadata = var.metadata.centos
    }

    "vm2" = { machine_type = "f1-micro", image_vm = "ubuntu-os-cloud/ubuntu-2004-lts", startup_script = file("startup.sh"), metadata = var.metadata["ubuntu"]
    }
  }
  subnetwork     = var.subnet_name
  ip_range       = var.ip_cidr_range
  tags           = var.tags
  machine_type   = each.value.machine_type
  vm_name        = each.key
  image_vm       = each.value.image_vm
  startup_script = each.value.startup_script
  metadata       = each.value.metadata
  email          = var.sa_email
  scope          = var.scopes_rules
  depends_on = [
    module.subnetwork
  ]
}

module "instances_count" {
  // list
  source         = "./modules/instances"
  count          = 2
  subnetwork     = var.subnet_name        // "az-subnet"
  ip_range       = var.ip_cidr_range      //"10.10.10.0/24"
  tags           = var.tags               //["web", "ssh"]
  vm_name        = "vm${count.index + 3}" //var.vm_count[count.index +1]
  machine_type   = var.vm_type            //"g1-small"
  image_vm       = var.image[count.index]
  startup_script = file(var.scripts[count.index])//("script.sh")
  metadata       = var.metadata_key[count.index]
  email          = var.sa_email
  scope          = var.scopes_rules
  depends_on = [
    module.subnetwork
  ]
}

locals {
  foreach_instnaces = values({ for instance_id, instances_foreach_id in module.instances :
    instance_id => instances_foreach_id.instance_id
  })
}

module "lb" {
  source = "./modules/load_balancer"
  group_name = "terraform-webservers"
  instances = concat(module.instances_count[*].instance_id, local.foreach_instnaces[*])
  global_forwarding_rule_name = "az-global-forwarding-https-rule"
  forwarding_port = "443"
  proxy_name = "az-proxy"
  ssl_name = "my-certificate"
  privat_key = file("private.key")
  certificate = file("certificate.crt")
  backend_name = "az-http-backend-service"
  backend_port_name = "http"
  backend_port = "HTTP"
  healthcheck_name = "az-http-healthcheck"
  url_map_name = "az-https-load-balancer"
}