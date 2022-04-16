variable "project" {
  type         = string
}
variable "region" {
  type         = string
}

variable "zone" {
  type         = string
}

variable "vm1_name" {
  type        = string
}

variable "vm2_name" {
  type        = string
}

variable "tags" {
  type         = list
}

variable "machine_type1" {
  type         = string
}

variable "machine_type2" {
  type         = string
}

variable "image_vm1" {
  type        = string
}

variable "image_vm2" {
  type        = string
}

variable "subnetwork" {
  type        = string
}

variable "ip_range" {
  type         = string  
}