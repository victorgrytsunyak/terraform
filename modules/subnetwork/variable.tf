variable "project" {
  type   = string
  default = "azimuthtv10-347408"
}

variable "ip_cidr_range" {
    type = string
    default = "10.10.10.0/24"
}

variable "subnet_name" {
  type    = string
  default = "az-subnet"
}
variable "network_name" {
  type    = string
  default = "az-network"
}