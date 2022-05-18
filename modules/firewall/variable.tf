variable "firewall_name" {
    type = string
}

variable "network" {
  type = string
}

variable "ip_source_ranges" {
  type = list(string)
}

variable "firewall_ports" {
  type = list(string)
}

variable "firewall_protocol" {
  type = string
}

variable "tags" {
  type = list(string)
}