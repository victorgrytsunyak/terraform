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
module "instances" {
  source = "./modules/instances"
  for_each = {

    "vm1" = { machine_type = "g1-small", image_vm = "centos-cloud/centos-7", startup_script = file("script.sh"), metadata = {
      enable-oslogin         = false
      block-project-ssh-keys = true
      ssh-keys               = <<EOT
    admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDc+ElEfosvoW6qPoCZWEyNCzD7cIrlBEfCauoEgI85eojs+KHIluZxPukiDCOo3siK3qJ3tJnd7/5oilVu2E8asA+iv/MGL9nASvN3uZjPXTy1ayAj4dHSLmSGBDLrgMafDmgMn7Hnc78FBXteb7NG9QTAplPbqJvBYGsCdLaZ11hkHXcjQU82NDsmoHumPb40BAQ5A5xNfg+SS4PnP6iyWnAgRELPcYkycX1n1oE0NiOwfZ0BvI16NNupsKja/lu8HyVnwLCiXyJ0FA31259T5ZJBjPRqscucPJIqU/yh5aGS/hVBCpkn5NcglltRoeIIGIEn5c/U1faXslBouars1P69EIRl4HS11LKSmX0PWHZez88rPy7CiLEPidvJO9uJmmB0gcnLbIzQj3JAXTFYT/qG8OlW4hVReAsTJ8dHtYqjVTN57CiN0/+FUS75eBlz2iCAT1E4wTN9PBWfXzMz4w0YLC5RNgCAolzjbhlNdTmTJAR4x6yRNQg/77OEL30= admin@DESKTOP-9EEH9LJ

    EOT
      }
    }

    "vm2" = { machine_type = "f1-micro", image_vm = "ubuntu-os-cloud/ubuntu-2004-lts", startup_script = file("startup.sh"), metadata = {
      enable-oslogin         = false
      block-project-ssh-keys = true
      ssh-keys               = <<EOT
    root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDc+ElEfosvoW6qPoCZWEyNCzD7cIrlBEfCauoEgI85eojs+KHIluZxPukiDCOo3siK3qJ3tJnd7/5oilVu2E8asA+iv/MGL9nASvN3uZjPXTy1ayAj4dHSLmSGBDLrgMafDmgMn7Hnc78FBXteb7NG9QTAplPbqJvBYGsCdLaZ11hkHXcjQU82NDsmoHumPb40BAQ5A5xNfg+SS4PnP6iyWnAgRELPcYkycX1n1oE0NiOwfZ0BvI16NNupsKja/lu8HyVnwLCiXyJ0FA31259T5ZJBjPRqscucPJIqU/yh5aGS/hVBCpkn5NcglltRoeIIGIEn5c/U1faXslBouars1P69EIRl4HS11LKSmX0PWHZez88rPy7CiLEPidvJO9uJmmB0gcnLbIzQj3JAXTFYT/qG8OlW4hVReAsTJ8dHtYqjVTN57CiN0/+FUS75eBlz2iCAT1E4wTN9PBWfXzMz4w0YLC5RNgCAolzjbhlNdTmTJAR4x6yRNQg/77OEL30= admin@DESKTOP-9EEH9LJ

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
  scope          = var.scopes_rules
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
    admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDc+ElEfosvoW6qPoCZWEyNCzD7cIrlBEfCauoEgI85eojs+KHIluZxPukiDCOo3siK3qJ3tJnd7/5oilVu2E8asA+iv/MGL9nASvN3uZjPXTy1ayAj4dHSLmSGBDLrgMafDmgMn7Hnc78FBXteb7NG9QTAplPbqJvBYGsCdLaZ11hkHXcjQU82NDsmoHumPb40BAQ5A5xNfg+SS4PnP6iyWnAgRELPcYkycX1n1oE0NiOwfZ0BvI16NNupsKja/lu8HyVnwLCiXyJ0FA31259T5ZJBjPRqscucPJIqU/yh5aGS/hVBCpkn5NcglltRoeIIGIEn5c/U1faXslBouars1P69EIRl4HS11LKSmX0PWHZez88rPy7CiLEPidvJO9uJmmB0gcnLbIzQj3JAXTFYT/qG8OlW4hVReAsTJ8dHtYqjVTN57CiN0/+FUS75eBlz2iCAT1E4wTN9PBWfXzMz4w0YLC5RNgCAolzjbhlNdTmTJAR4x6yRNQg/77OEL30= admin@DESKTOP-9EEH9LJ

    EOT
      }
  email          = var.sa_email
  scope          = []
  depends_on = [
    google_compute_subnetwork.az-subnet
  ]
}

resource "google_compute_instance_group" "webservers" {
  project = var.project
  zone = var.zone
  name        = "terraform-webservers"
  description = "Terraform instance group"
  network     = google_compute_network.az-network.id


  instances = [
   abc = {a=1,b=2,c=3}
   abc["a"]
    "https://www.googleapis.com/compute/v1/projects/azimuthtv10-347408/zones/europe-west3-b/instances/instance0",
    "https://www.googleapis.com/compute/v1/projects/azimuthtv10-347408/zones/europe-west3-b/instances/instance1",
    "https://www.googleapis.com/compute/v1/projects/azimuthtv10-347408/zones/europe-west3-b/instances/vm1",
    "https://www.googleapis.com/compute/v1/projects/azimuthtv10-347408/zones/europe-west3-b/instances/vm2",
  ]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }
  depends_on = [
    module.instances, module.vms_count
  ]
}

resource "google_compute_backend_service" "backend_https_service" {
  name      = "backend-https-service"
  port_name = "https"
  protocol  = "HTTPS"

  backend {
    group = google_compute_instance_group.webservers.id
  }

  health_checks = [
    google_compute_https_health_check.backend_https_health.id,
  ]
}

resource "google_compute_https_health_check" "backend_https_health" {
  name         = "https-health"
  request_path = "/health_check"
}

resource "google_compute_backend_service" "backend_http_service" {
  name      = "backend-http-service"
  port_name = "http"
  protocol  = "HTTP"

  backend {
    group = google_compute_instance_group.webservers.id
  }

  health_checks = [
    google_compute_http_health_check.backend_http_health.id,
  ]
}

resource "google_compute_http_health_check" "backend_http_health" {
  name         = "http-health"
  request_path = "/health_check"
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