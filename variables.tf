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