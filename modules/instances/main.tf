terraform {
    required_version = ">=1.1.3"
}

resource "google_compute_instance" "vm-centos" {
  project                   = var.project
  zone                      = var.zone
  name                      = var.vm1_name
  machine_type              = var.machine_type1
  tags                      = var.tags
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.image_vm1
    }
  }
  //Network config
  network_interface {
    subnetwork = var.subnetwork //google_compute_subnetwork.az-subnet.id
    access_config {
    }
  }
  // Adding ssh keys
  metadata = {
    enable-oslogin         = false
    block-project-ssh-keys = true
    "ssh-keys"             = <<EOT

    admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbi+rm7By+HYqpS0Uy5FMmGD50Mf7hoW6iHIVru28W4/MZAK9XmZXzI1KKDA/eS4g0E5XScue/is3329VGBEljn6ZCO/FO6xEhTv4UEklPIGJDWa89/IuX39KE/7uI0wQ+Fjj35YEhbe8z9cmWrBbba0Z7zQDZpAxKVEU3+R5MHc+O1Ctm6PbAdtIsDGjHx3zYyBp3tT9SJbxIp2m1DNEa1BMkNXb2EBbR8V8eCHKxxkOhgv06I//xkQGIB9vySv1AXwEixg4iW93eeMnzg0dYSeCvt+PhStpGnekqfRow74LWfwDo7FwP2A0Ycmc1KKLOZk9N8kR6ghzBiJ5KYdOoYoL4ezNyD0kZjrfmP/QRaOxhrrvFsJ8LOnLQps6RQyDIOteZ4GYfr+1zG8AfQF0ZMVVUketNFsQ2hpMms9rVWE0NAis4evoGo6s6RoqElgrWrd3PYKb8t0+dmFa3kHXLHD84mn4sgnt8dqbuayW/hljGzELYmK1byd/JcONgLRc= admin@DESKTOP-9EEH9LJ
    EOT
  }
  metadata_startup_script = file("script.sh")
}

//Second virtual machine
resource "google_compute_instance" "vm-ubuntu" {
  project                   = var.project
  zone                      = var.zone
  name                      = var.vm2_name
  machine_type              = var.machine_type2
  tags                      = var.tags //list
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.image_vm2 // var.image
    }
  }
  network_interface {
    subnetwork = var.subnetwork  //var.subnetwork
    access_config {

    }
  }
  metadata = {
    enable-oslogin         = false
    block-project-ssh-keys = true
   "ssh-keys"             = <<EOT
    
    root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbi+rm7By+HYqpS0Uy5FMmGD50Mf7hoW6iHIVru28W4/MZAK9XmZXzI1KKDA/eS4g0E5XScue/is3329VGBEljn6ZCO/FO6xEhTv4UEklPIGJDWa89/IuX39KE/7uI0wQ+Fjj35YEhbe8z9cmWrBbba0Z7zQDZpAxKVEU3+R5MHc+O1Ctm6PbAdtIsDGjHx3zYyBp3tT9SJbxIp2m1DNEa1BMkNXb2EBbR8V8eCHKxxkOhgv06I//xkQGIB9vySv1AXwEixg4iW93eeMnzg0dYSeCvt+PhStpGnekqfRow74LWfwDo7FwP2A0Ycmc1KKLOZk9N8kR6ghzBiJ5KYdOoYoL4ezNyD0kZjrfmP/QRaOxhrrvFsJ8LOnLQps6RQyDIOteZ4GYfr+1zG8AfQF0ZMVVUketNFsQ2hpMms9rVWE0NAis4evoGo6s6RoqElgrWrd3PYKb8t0+dmFa3kHXLHD84mn4sgnt8dqbuayW/hljGzELYmK1byd/JcONgLRc= admin@DESKTOP-9EEH9LJ
    EOT
  }
  metadata_startup_script = file("startup.sh")
}
