terraform {
    required_version = ">=1.1.3"
}
resource "google_compute_network" "az-network" {
  project                 = var.project
  name                    = "az-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "az-subnet" {
  project       = var.project
  name          = "az-subnetwork"
  ip_cidr_range = var.ip_cidr_range
  region        = var.region
  network       = google_compute_network.az-network.id

log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_instance" "vm-centos" {
  project                   = var.project
  zone                      = var.zone
  name                      = "vm1"
  machine_type              = var.machine_type
  tags                      = ["ssh", "web"]
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
resource "google_compute_instance" "vm-ubuntu" {
  project                   = var.project
  zone                      = var.zone
  name                      = "vm2"
  machine_type              = var.machine_type
  tags                      = ["ssh", "web"]
  allow_stopping_for_update = true

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
