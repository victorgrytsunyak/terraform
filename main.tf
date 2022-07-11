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
    "compute.networkAdmin", "storage.admin" //"storage.objectAdmin"
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
  ip_source_ranges  = ["194.44.223.172/30"]     //"194.44.223.172/30", "172.64.0.0/13", "173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22", "141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20", "197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13", "104.24.0.0/14", "131.0.72.0/22"
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
  ip_cidr_range = "10.0.0.0/18"

  depends_on = [
    module.network
  ]
}

## Module for installing VMs
# module "instances" {
#   source = "./modules/instances"
#   for_each = {

#     "vm1" = {
#       machine_type   = "g1-small",
#       image_vm       = "centos-cloud/centos-7",
#       startup_script = file("script.sh"),
#       metadata       = var.metadata.centos
#     }

#     "vm2" = {
#       machine_type   = "f1-micro",
#       image_vm       = "ubuntu-os-cloud/ubuntu-2004-lts",
#       startup_script = file("startup.sh"),
#       metadata       = var.metadata["ubuntu"]
#     }
#   }
#   subnetwork     = var.subnet_name
#   ip_range       = var.ip_cidr_range
#   tags           = var.tags
#   machine_type   = each.value.machine_type
#   vm_name        = each.key
#   image_vm       = each.value.image_vm
#   startup_script = each.value.startup_script
#   metadata       = each.value.metadata
#   email          = var.sa_email
#   scope          = var.scopes_rules
#   depends_on = [
#     module.subnetwork
#   ]
# }

# module "instances_count" {
#   // list
#   source         = "./modules/instances"
#   count          = 2
#   subnetwork     = var.subnet_name        // "az-subnet"
#   ip_range       = var.ip_cidr_range      //"10.10.10.0/24"
#   tags           = var.tags               //["web", "ssh"]
#   vm_name        = "vm${count.index + 3}" //var.vm_count[count.index +1]
#   machine_type   = var.vm_type            //"g1-small"
#   image_vm       = var.image[count.index]
#   startup_script = file(var.scripts[count.index]) //("script.sh")
#   metadata       = var.metadata_key[count.index]
#   email          = var.sa_email
#   scope          = var.scopes_rules
#   depends_on = [
#     module.subnetwork
#   ]
# }

# locals {
#   foreach_instnaces = values({ for instance_id, instances_foreach_id in module.instances :
#     instance_id => instances_foreach_id.instance_id
#   })
# }

# module "lb" {
#   source            = "./modules/load_balancer"
#   instances         = concat(module.instances_count[*].instance_id, local.foreach_instnaces[*])
#   lb_ip             = google_compute_global_address.lb_global_ip.address
#   forwarding_port   = "443"
#   privat_key        = file("private.key")
#   certificate       = file("certificate.crt")
#   backend_port_name = "http"
#   backend_port      = "HTTP"
#   healthcheck_port  = 80
# }

resource "google_compute_router" "router" {
  name    = "${var.name_prefix}-router"
  region  = var.region
  network = module.network.network_id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.name_prefix}-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = var.subnet_name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  # nat_ips = [google_compute_address.nat.self_link]

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
  depends_on = [
    module.subnetwork
  ]
}

# resource "google_compute_global_address" "lb_global_ip" {
#   name         = "${var.name_prefix}-global-appserver-ip"
#   address_type = "EXTERNAL"
#   ip_version   = "IPV4"
# }

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

resource "google_service_account" "cluster_sa" {
  project      = var.project
  account_id   = "cluster-admin"
  display_name = "cluster-admin"
  description  = "cluster_sa"
}

resource "google_project_iam_member" "cluster_admin_roles" {
  for_each = toset([
    "container.clusterAdmin", "container.admin", "storage.objectAdmin", "cloudsql.admin" //"storage.objectAdmin"
  ])
  project = var.project
  role    = "roles/${each.key}"
  member  = "serviceAccount:cluster-admin@azimuthtv10-347408.iam.gserviceaccount.com"
}

resource "google_container_cluster" "test_cluster" {
  name               = "${var.project}-gke"
  location           = var.region
  # initial_node_count = 1
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  networking_mode          = "VPC_NATIVE"

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pod-range"
    services_secondary_range_name = "k8s-service-range"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
       cidr_blocks {
         cidr_block   = "10.0.0.0/18"
         display_name = "private-subnet"
       }
  }


  node_config {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.cluster_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    tags = ["web", "ssh"]
  }
  
  timeouts {
    create = "30m"
    update = "40m"
  }

  network    = var.network_name
  subnetwork = var.subnet_name

  # Enabling Autopilot for this cluster
  enable_autopilot = true

  depends_on = [
    module.subnetwork
  ]
}

// The user-data script on Bastion instance provisioning.
data "template_file" "startup_script" {
  template = <<-EOF
  apt-get update -y
  apt install snapd
  snap install kubectl --classic
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
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  // Install tinyproxy on startup.
  metadata_startup_script = data.template_file.startup_script.rendered

  network_interface {
    subnetwork = var.subnet_name


    access_config {
      // Not setting "nat_ip", use an ephemeral external IP.

    }
  }

  metadata = {
    enable-oslogin         = false
    block-project-ssh-keys = true
    ssh-keys               = <<EOT
    root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9xQdGKRGXZGPWpDzhFukeu9anyva+Q7XkhCJcs6SAlu8QeuzsYwMbYuNwQOFOPzEeK5G6UTbaBMJ3NMXTrc3QwkVL2Wi+hQoPGK/kGvazxWtnpSzWcrksnYWeMo8il3BY+pXSOkuq0Yd8WmW6o+yMEV4x3ThsjtFzyGZ7Y2djTU8KqC3JL49USN+0w7bgAFtCGj4YqOR3z7e3NcdxZ49VCtZKFD3/d6zblbqepW5T8ht2PW2QSGb4nH7Nx+OeZuId2afogCoCFRHVQhMpHf6/IdnyaGGHqiwX+og81nEzGobTd42mGj4kdNBIwPAnpI3mACJLoHj75NB0ns10CRW1rWXxn0w1wzZmwA/TSjWGuieGpjSsvKcn/upoPmj6pDa7/I0jNVOhgSxjuqj/v98D995r7JkHPjOEkptZf37lWUeulS5Wh0HaQwErWb0K3huXX8ZdlUuJ1Xq9/V9eg0OxSSk6e/zsMuXxGLrf2yDKDr+Ev4ssCQgeZ2CaznRFfBs= admin@DESKTOP-9EEH9LJ

     EOT
  }

  // Allow the instance to be stopped by Terraform when updating configuration.
  allow_stopping_for_update = true

  service_account {
    email  = google_service_account.cluster_sa.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    module.subnetwork
  ]
}

resource "google_compute_global_address" "private_ip_address" {
  provider = google

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.network.network_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google

  network                 = module.network.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "db_instance" {
  provider = google

  name             = "db-${random_id.db_name_suffix.hex}"
  region           = var.region
  database_version = "MYSQL_5_7"
  deletion_protection = false
  root_password    = "mydbpassword"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = module.network.network_id
    }
  }
}

resource "google_sql_user" "users" {
  name     = "db_user"
  instance = google_sql_database_instance.db_instance.name
  password = "db_password"
}

resource "google_service_account_iam_binding" "cluster-admin-iam" {
  service_account_id = google_service_account.cluster_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:cluster-admin@azimuthtv10-347408.iam.gserviceaccount.com",
  ]
}