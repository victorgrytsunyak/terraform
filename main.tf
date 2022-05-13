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
  image_vm       = var.image
  startup_script = file("script.sh")
  metadata       = var.metadata.centos
  email          = var.sa_email
  scope          = []
  depends_on = [
    module.subnetwork
  ]
}

resource "google_compute_global_forwarding_rule" "global_forwarding_rule" {
  name       = "az-global-forwarding-rule"
  project    = var.project
  target     = google_compute_target_http_proxy.target_http_proxy.self_link
  port_range = "80"
}

# used by one or more global forwarding rule to route incoming HTTP requests to a URL map
resource "google_compute_target_http_proxy" "target_http_proxy" {
  name    = "az-proxy"
  project = var.project
  url_map = google_compute_url_map.url_map.self_link
}

# defines a group of virtual machines that will serve traffic for load balancing
resource "google_compute_backend_service" "backend_service" {
  name          = "az-backend-service"
  project       = var.project
  port_name     = "http"
  protocol      = "HTTP"
  health_checks = ["${google_compute_health_check.healthcheck.self_link}"]

  backend {
    group                 = google_compute_instance_group.webservers.self_link
    balancing_mode        = "RATE"
    max_rate_per_instance = 100
  }
}

resource "google_compute_instance_group" "webservers" {
  project     = var.project
  zone        = var.zone
  name        = "terraform-webservers"
  description = "Terraform instance group"

  instances =  "${module.instances_count[*].instance_id}"
  
  //values({ for instance_id, instances_foreach_id in module.instances :
   // instance_id => instances_foreach_id.instance_id}) 
    //module.instances_count[*].instance_id
  //module.instances_count[*].instance_id 
  
  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }

}

resource "google_compute_health_check" "healthcheck" {
  name               = "az-healthcheck"
  timeout_sec        = 1
  check_interval_sec = 1
  http_health_check {
    port = 80
  }
}

# used to route requests to a backend service based on rules that you define for the host and path of an incoming URL
resource "google_compute_url_map" "url_map" {
  name            = "az-load-balancer"
  project         = var.project
  default_service = google_compute_backend_service.backend_service.self_link
}

# locals{
#   lb_instances = concat([tolist(module.instances_count[*].instance_id)]) //(module.instances.*.instance_id)
# }