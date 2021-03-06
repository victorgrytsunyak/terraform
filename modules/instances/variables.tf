variable "project" {
  type         = string
  default      = "azimuthtv10-347408"
}
variable "region" {
  type         = string
  default      = "europe-west3"
}

variable "zone" {
  type         = string
  default      = "europe-west3-b"
}

variable "vm_name" {
  type        = string
}

variable "tags" {
  type         = list
}

variable "machine_type" {
  type         = string
}

variable "image_vm" {
  type        = string
}

variable "network" {
  type = string
  default = "az-network"
}

variable "subnetwork" {
  type        = string
}

variable "ip_range" {
  type         = string  
}

variable "startup_script" {
  type        = string
}

variable "metadata" {
  type        = map
}

variable "email" {
  type = string
  default = "azimuth@azimuthtv10-347408.iam.gserviceaccount.com"
}

variable "scope" {
  type  = list
  default = ["cloud-platform"]
}