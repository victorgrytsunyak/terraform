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

variable "group_name" {
    type = string
}

variable "global_forwarding_rule_name" {
    type = string
}

variable "forwarding_port" {
    type = string
}

variable "proxy_name" {
  type = string
}

variable "ssl_name" {
  type = string
}

variable "privat_key" {
  type = string
}

variable "certificate" {
  type = string
}

variable "backend_name" {
  type = string
}

variable "backend_port_name" {
  type = string
}

variable "backend_port" {
  type = string
}

variable "healthcheck_name" {
    type = string
}

variable "url_map_name" {
  type = string
}

variable "instances" {
  type = list
}