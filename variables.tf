variable "project" {
  type    = string
  default = "azimuthtv10-347408"
}
variable "region" {
  type    = string
  default = "europe-west3"
}

variable "zone" {
  type    = string
  default = "europe-west3-b"
}

variable "sa_email" {
  type    = string
  default = "azimuth@azimuthtv10-347408.iam.gserviceaccount.com"
}

variable "scopes_rules" {
  type    = list(any)
  default = ["storage-rw"]
}

variable "tags" {
  type    = list(any)
  default = ["web", "ssh"]
}

variable "ip" {
  type    = string
  default = "10.10.10.0/24"
}

variable "vm_type" {
  type    = string
  default = "g1-small"
}

variable "subnet" {
  type    = string
  default = "az-subnet"
}

variable "subnet_name" {
  type    = string
  default = "az-subnet"
}

variable "network_name" {
  type    = string
  default = "az-network"
}

variable "ssh_key_ub" {
  type = map(any)
  default = {
    enable-oslogin         = false
    block-project-ssh-keys = true
    "ssh-keys"             = <<EOT
    
    root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbi+rm7By+HYqpS0Uy5FMmGD50Mf7hoW6iHIVru28W4/MZAK9XmZXzI1KKDA/eS4g0E5XScue/is3329VGBEljn6ZCO/FO6xEhTv4UEklPIGJDWa89/IuX39KE/7uI0wQ+Fjj35YEhbe8z9cmWrBbba0Z7zQDZpAxKVEU3+R5MHc+O1Ctm6PbAdtIsDGjHx3zYyBp3tT9SJbxIp2m1DNEa1BMkNXb2EBbR8V8eCHKxxkOhgv06I//xkQGIB9vySv1AXwEixg4iW93eeMnzg0dYSeCvt+PhStpGnekqfRow74LWfwDo7FwP2A0Ycmc1KKLOZk9N8kR6ghzBiJ5KYdOoYoL4ezNyD0kZjrfmP/QRaOxhrrvFsJ8LOnLQps6RQyDIOteZ4GYfr+1zG8AfQF0ZMVVUketNFsQ2hpMms9rVWE0NAis4evoGo6s6RoqElgrWrd3PYKb8t0+dmFa3kHXLHD84mn4sgnt8dqbuayW/hljGzELYmK1byd/JcONgLRc= admin@DESKTOP-9EEH9LJ
    EOT
  }
}

variable "ssh_key_cen" {
  type = map(any)
  default = {
    enable-oslogin         = false
    block-project-ssh-keys = true
    "ssh-keys"             = <<EOT
    
    admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbi+rm7By+HYqpS0Uy5FMmGD50Mf7hoW6iHIVru28W4/MZAK9XmZXzI1KKDA/eS4g0E5XScue/is3329VGBEljn6ZCO/FO6xEhTv4UEklPIGJDWa89/IuX39KE/7uI0wQ+Fjj35YEhbe8z9cmWrBbba0Z7zQDZpAxKVEU3+R5MHc+O1Ctm6PbAdtIsDGjHx3zYyBp3tT9SJbxIp2m1DNEa1BMkNXb2EBbR8V8eCHKxxkOhgv06I//xkQGIB9vySv1AXwEixg4iW93eeMnzg0dYSeCvt+PhStpGnekqfRow74LWfwDo7FwP2A0Ycmc1KKLOZk9N8kR6ghzBiJ5KYdOoYoL4ezNyD0kZjrfmP/QRaOxhrrvFsJ8LOnLQps6RQyDIOteZ4GYfr+1zG8AfQF0ZMVVUketNFsQ2hpMms9rVWE0NAis4evoGo6s6RoqElgrWrd3PYKb8t0+dmFa3kHXLHD84mn4sgnt8dqbuayW/hljGzELYmK1byd/JcONgLRc= admin@DESKTOP-9EEH9LJ
    EOT
  }
}