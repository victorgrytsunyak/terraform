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

variable "forwarding_port" {
    type = string
}

variable "ssl_name_prefix" {
  type = string
  default = "az"
}

variable "privat_key" {
  type = string
}

variable "certificate" {
  type = string
}

variable "backend_port_name" {
  type = string
}

variable "backend_port" {
  type = string
}

variable "instances" {
  type = list
}

variable "healthcheck_port" {
  type = string
}

variable "lb_ip" {
  type = string
}

variable "names_prefix" {
  type = string
  default = "az"
}