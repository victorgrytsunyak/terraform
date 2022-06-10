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
    "compute.networkAdmin" //"storage.objectAdmin"
  ])
  project = var.project
  role    = "roles/${each.key}"
  member  = "serviceAccount:azimuth@azimuthtv10-347408.iam.gserviceaccount.com"
}

// Firewall set up
module "ssh" {
  source            = "./modules/firewall"
  firewall_name     = "allow-ssh"
  network           = module.network.network_id //"${var.name_prefix}network"
  ip_source_ranges  = ["194.44.223.172/30"] //"194.44.223.172/30", "172.64.0.0/13", "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20", "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13", "104.24.0.0/14", "131.0.72.0/22"
  firewall_ports    = ["22"]
  firewall_protocol = "tcp"
  tags              = ["ssh"]
  depends_on = [
    module.network
  ]
}

module "bastion_ssh" {
  source            = "./modules/firewall"
  firewall_name     = "bastion-ssh"
  network           = module.network.network_id //"${var.name_prefix}network"
  ip_source_ranges  = ["194.44.223.172/30"] //"194.44.223.172/30", "172.64.0.0/13", "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20", "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13", "104.24.0.0/14", "131.0.72.0/22"
  firewall_ports    = ["22"]
  firewall_protocol = "tcp"
  tags              = ["ssh"]
  depends_on = [
    module.network
  ]
}

module "http_https" {
  source            = "./modules/firewall"
  firewall_name     = "allow-http-https"
  network           = module.network.network_id //"${var.name_prefix}network"
  ip_source_ranges  = ["0.0.0.0/0"]
  firewall_ports    = ["80", "443"]
  firewall_protocol = "tcp"
  tags              = ["web"]
  depends_on = [
    module.network
  ]
}

resource "google_storage_bucket" "azimuth-bucket" {
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
  network_name = "${var.name_prefix}-network"
}

#module for creating subnetwork
module "subnetwork" {
  source        = "./modules/subnetwork"
  subnet_name   = "${var.name_prefix}-subnet"
  ip_cidr_range = "10.10.10.0/24"
  depends_on = [
    module.network
  ]
}

## Module for installing VMs
module "instances" {
  source = "./modules/instances"
  for_each = {

    "vm1" = {
      machine_type   = "g1-small",
      image_vm       = "centos-cloud/centos-7",
      startup_script = file("script.sh"),
      metadata       = var.metadata.centos
    }

    "vm2" = {
      machine_type   = "f1-micro",
      image_vm       = "ubuntu-os-cloud/ubuntu-2004-lts",
      startup_script = file("startup.sh"),
      metadata       = var.metadata["ubuntu"]
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
  startup_script = file(var.scripts[count.index]) //("script.sh")
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
  source            = "./modules/load_balancer"
  instances         = concat(module.instances_count[*].instance_id, local.foreach_instnaces[*])
  lb_ip             = google_compute_global_address.lb_global_ip.address
  forwarding_port   = "443"
  privat_key        = file("private.key")
  certificate       = file("certificate.crt")
  backend_port_name = "http"
  backend_port      = "HTTP"
  healthcheck_port  = 80
}

resource "google_compute_router" "router" {
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = module.network.network_id

  bgp {
    asn = 64514
  }
}

resource "google_compute_route" "egress_internet" {
  name             = "egress-internet"
  dest_range       = "0.0.0.0/0"
  network          = var.network_name
  next_hop_gateway = "default-internet-gateway"
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.name_prefix}-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_global_address" "lb_global_ip" {
  name         = "${var.name_prefix}-global-appserver-ip"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

# resource "google_project_iam_custom_role" "custom-bucket-role" {
#   project = var.project
#   role_id = "BucketAdmin"
#   title   = "Custom role for bucket admin"
#   permissions = [
#     "firebase.projects.get",
#     "orgpolicy.policy.get",
#     "storage.buckets.create",
#     "storage.buckets.createTagBinding",
#     "storage.buckets.get",
#     "storage.buckets.getIamPolicy",
#     "storage.buckets.list",
#     "storage.buckets.listEffectiveTags",
#     "storage.buckets.listTagBindings",
#     "storage.buckets.setIamPolicy",
#     "storage.buckets.update",
#     "storage.multipartUploads.abort",
#     "storage.multipartUploads.create",
#     "storage.multipartUploads.list",
#     "storage.multipartUploads.listParts",
#     "storage.objects.create",
#     "storage.objects.delete",
#     "storage.objects.get",
#     "storage.objects.getIamPolicy",
#     "storage.objects.list",
#     "storage.objects.setIamPolicy",
#     "storage.objects.update"
#   ]
# }

# resource "google_project_iam_binding" "custom_role" {
#   role    = google_project_iam_custom_role.custom-bucket-role.id
#   project = var.project
#   members = ["serviceAccount:azimuth@azimuthtv10-347408.iam.gserviceaccount.com"]
# }

locals {
  cluster_master_ip_cidr_range   = "10.100.100.0/28"
  cluster_pods_ip_cidr_range     = "10.101.0.0/16"
  cluster_services_ip_cidr_range = "10.102.0.0/16"
}

resource "google_container_cluster" "test_cluster" {
  name     = "${var.project}-gke"
  location = var.region
  initial_node_count = 1

  network    = var.network_name
  subnetwork = var.subnet_name
  
  ip_allocation_policy {
    cluster_ipv4_cidr_block = local.cluster_pods_ip_cidr_range
    services_ipv4_cidr_block = local.cluster_services_ip_cidr_range
  }
 
  logging_service = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  maintenance_policy {
    daily_maintenance_window {
      start_time = "02:00"
    }
  }

  master_auth {
    # username = "my-user"
    # password = "useYourOwnPassword."

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = "${local.cluster_master_ip_cidr_range}" != null ? ["${local.cluster_master_ip_cidr_range}"] : []
    content {
      cidr_blocks {
        cidr_block   = master_authorized_networks_config.value
        display_name = "External Control Plane access"
      }
    }
  }

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = local.cluster_master_ip_cidr_range
  }

  release_channel {
      channel = "STABLE"
  }

  # addons_config {
  #   // Enable network policy (Calico)
  #   # network_policy_config {
  #   #     disabled = false
  #   #   }
  # }

  /* Enable network policy configurations (like Calico).
  For some reason this has to be in here twice. */
  # network_policy {
  #   enabled = "true"
  # }

  # workload_identity_config {
  #   identity_namespace = format("%s.svc.id.google", var.project)
  # }

  # Enabling Autopilot for this cluster
  enable_autopilot = true
}

// The user-data script on Bastion instance provisioning.
data "template_file" "startup_script" {
  template = <<-EOF
  sudo apt-get update -y
  sudo apt-get install -y tinyproxy
  EOF
}

// The Bastion host.
resource "google_compute_instance" "bastion" {
  name         = "bastion-host"
  machine_type = "e2-micro"
  zone         = var.zone
  project      = var.project
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  // Install tinyproxy on startup.
  metadata_startup_script = data.template_file.startup_script.rendered

  network_interface {
    subnetwork = var.subnet_name


    access_config {
      // Not setting "nat_ip", use an ephemeral external IP.
      network_tier = "STANDARD"
    }
  }

  // Allow the instance to be stopped by Terraform when updating configuration.
  allow_stopping_for_update = true

  service_account {
    email  = google_service_account.SA.email
    scopes = ["cloud-platform"]
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}