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

variable "metadata_cen" {
  type = map
  default = {
      enable-oslogin         = false
      block-project-ssh-keys = true
      ssh-keys               = <<EOT
    admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDc+ElEfosvoW6qPoCZWEyNCzD7cIrlBEfCauoEgI85eojs+KHIluZxPukiDCOo3siK3qJ3tJnd7/5oilVu2E8asA+iv/MGL9nASvN3uZjPXTy1ayAj4dHSLmSGBDLrgMafDmgMn7Hnc78FBXteb7NG9QTAplPbqJvBYGsCdLaZ11hkHXcjQU82NDsmoHumPb40BAQ5A5xNfg+SS4PnP6iyWnAgRELPcYkycX1n1oE0NiOwfZ0BvI16NNupsKja/lu8HyVnwLCiXyJ0FA31259T5ZJBjPRqscucPJIqU/yh5aGS/hVBCpkn5NcglltRoeIIGIEn5c/U1faXslBouars1P69EIRl4HS11LKSmX0PWHZez88rPy7CiLEPidvJO9uJmmB0gcnLbIzQj3JAXTFYT/qG8OlW4hVReAsTJ8dHtYqjVTN57CiN0/+FUS75eBlz2iCAT1E4wTN9PBWfXzMz4w0YLC5RNgCAolzjbhlNdTmTJAR4x6yRNQg/77OEL30= admin@DESKTOP-9EEH9LJ

    EOT
      }
  
}