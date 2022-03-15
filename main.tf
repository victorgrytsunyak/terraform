provider "google" {
  credentials = file("gcp_service_account_cred.json")
  project     = "azimuth-80700"
  region      = "europe-west3"
  zone        = "europe-west3-b"
}


// First virtual machine
resource "google_compute_instance" "vm_azimuth" {
  name         = "vm1"
  machine_type = "f1-micro"      
  tags         = ["ssh", "web"]

    boot_disk {
      initialize_params {
        image = "centos-cloud/centos-7"
        }
      }    
  //Network config
    network_interface {       
        network         = "default"
        access_config {
        network_tier    = "STANDARD"
        }
      } 
// Adding ssh keys
metadata = {
    enable-oslogin = false
    block-project-ssh-keys = true
    "ssh-keys" = <<EOT
    admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCdBNZcZ26lztFNd4d6plKF9dal321CQO0QnlLkWNo6fwCVk2tl0h35q7q6/groTROa//tYgIg3MIEDfdBXONj/fnQnYOvXFl3egwyHbkDAmmtrtGW2qr0f3AzPIaQw4nXxOys6lKvGCpgVJ+7r2BAweuc926ZFHyNuETkSOkotUJ6WHBhCgGj4uxuAU2/FSzIroWPgL3L3X0CxUSOV8ex4JpDK0TIDiB3Ed/WZZFdYZqty19jiwsC17SIVSSabUTXCGzFTKqFvYDY3q7YGwEfQnnOLNHMLqwaq/3fxoCXx75z+GkrOIxQIG1nYHU8D1ppAn+TpM92gICmKPJ/iJJj4pp8B21SzMK6S+PE7IJWZ37FrqhJdMgavIsukjsa7qm9jp6U4a46pihZEBwjM284EBXIN9496AUEkcC+5vTbi1Uzr80QdPf3XmKkC+2a/8P7eHSPT7qhO1unz92No6OJ2NnU46j4o2fxjOzHVOGyo7BRyyMW1f+UDtbKubI9xp3U= admin
    EOT
  }
metadata_startup_script = file("script.sh")

service_account {
    email  = "azimuth@azimuth-80700.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

//Second virtual machine
resource "google_compute_instance" "vm_ubuntu" {
      name         = "vm2"
      machine_type = "f1-micro"      
      tags         = ["ssh", "web"]

       boot_disk {
        initialize_params {
          image    = "ubuntu-os-cloud/ubuntu-2004-lts"
        }
      }    
      network_interface {       
        network        = "default"
        access_config {
        network_tier   = "STANDARD"
        }
      } 
metadata = {
    enable-oslogin = false
    block-project-ssh-keys = true
    "ssh-keys" = <<EOT
    root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCdBNZcZ26lztFNd4d6plKF9dal321CQO0QnlLkWNo6fwCVk2tl0h35q7q6/groTROa//tYgIg3MIEDfdBXONj/fnQnYOvXFl3egwyHbkDAmmtrtGW2qr0f3AzPIaQw4nXxOys6lKvGCpgVJ+7r2BAweuc926ZFHyNuETkSOkotUJ6WHBhCgGj4uxuAU2/FSzIroWPgL3L3X0CxUSOV8ex4JpDK0TIDiB3Ed/WZZFdYZqty19jiwsC17SIVSSabUTXCGzFTKqFvYDY3q7YGwEfQnnOLNHMLqwaq/3fxoCXx75z+GkrOIxQIG1nYHU8D1ppAn+TpM92gICmKPJ/iJJj4pp8B21SzMK6S+PE7IJWZ37FrqhJdMgavIsukjsa7qm9jp6U4a46pihZEBwjM284EBXIN9496AUEkcC+5vTbi1Uzr80QdPf3XmKkC+2a/8P7eHSPT7qhO1unz92No6OJ2NnU46j4o2fxjOzHVOGyo7BRyyMW1f+UDtbKubI9xp3U= admin
    EOT
}
metadata_startup_script = file("startup.sh")
service_account {
    email  = "azimuth@azimuth-80700.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}
 
// Firewall set up
resource "google_compute_firewall" "ssh" {
        name          = "allow-ssh"
        network       = "default"
        source_ranges = ["0.0.0.0/0"]
        

        allow {
        ports       = ["22"]
        protocol    = "tcp"
      }
        target_tags = ["ssh"]
}
resource "google_compute_firewall" "http" {
        name          = "allow-http"
        network       = "default"
        source_ranges = ["0.0.0.0/0"]
        

        allow {
        ports       = ["80"]
        protocol    = "tcp"
      }
        target_tags = ["web"]
}
resource "google_compute_firewall" "https" {
        name          = "allow-https"
        network       = "default"
        source_ranges = ["0.0.0.0/0"]
        

        allow {
          ports     = ["443"]
          protocol  = "tcp"
      }
        target_tags = ["web"]
}