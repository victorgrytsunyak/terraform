terraform {
    required_version = ">=1.1.3"
}

resource "google_compute_instance" "vm" {
  project                   = var.project
  zone                      = var.zone
  name                      = var.vm_name
  machine_type              = var.machine_type
  tags                      = var.tags
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.image_vm
    }
  }
  //Network config
  network_interface {
    subnetwork = var.subnetwork
    access_config {
      
    }
  }
  // Adding ssh keys
  metadata = var.metadata 
  metadata_startup_script = var.startup_script

  service_account {
    email  = var.email // "azimuth@azimuthtv10-347408.iam.gserviceaccount.com"
    scopes = var.scope  // ["storage-rw"]
  }
}