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

variable "ip_cidr_range" {
  type    = string
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

variable "scopes_rules" {
  type    = list(any)
  default = ["storage-rw"]
}

variable "tags" {
  type    = list(any)
  default = ["web", "ssh"]
}

variable "vm_type" {
  type    = string
  default = "g1-small"
}

variable "metadata" {
  type = map(any)
  default = {
    ubuntu = {
      enable-oslogin         = false
      block-project-ssh-keys = true
      ssh-keys               = <<EOT
    root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9xQdGKRGXZGPWpDzhFukeu9anyva+Q7XkhCJcs6SAlu8QeuzsYwMbYuNwQOFOPzEeK5G6UTbaBMJ3NMXTrc3QwkVL2Wi+hQoPGK/kGvazxWtnpSzWcrksnYWeMo8il3BY+pXSOkuq0Yd8WmW6o+yMEV4x3ThsjtFzyGZ7Y2djTU8KqC3JL49USN+0w7bgAFtCGj4YqOR3z7e3NcdxZ49VCtZKFD3/d6zblbqepW5T8ht2PW2QSGb4nH7Nx+OeZuId2afogCoCFRHVQhMpHf6/IdnyaGGHqiwX+og81nEzGobTd42mGj4kdNBIwPAnpI3mACJLoHj75NB0ns10CRW1rWXxn0w1wzZmwA/TSjWGuieGpjSsvKcn/upoPmj6pDa7/I0jNVOhgSxjuqj/v98D995r7JkHPjOEkptZf37lWUeulS5Wh0HaQwErWb0K3huXX8ZdlUuJ1Xq9/V9eg0OxSSk6e/zsMuXxGLrf2yDKDr+Ev4ssCQgeZ2CaznRFfBs= admin@DESKTOP-9EEH9LJ

     EOT
    }
    centos = {
      enable-oslogin         = false
      block-project-ssh-keys = true
      ssh-keys               = <<EOT
    admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9xQdGKRGXZGPWpDzhFukeu9anyva+Q7XkhCJcs6SAlu8QeuzsYwMbYuNwQOFOPzEeK5G6UTbaBMJ3NMXTrc3QwkVL2Wi+hQoPGK/kGvazxWtnpSzWcrksnYWeMo8il3BY+pXSOkuq0Yd8WmW6o+yMEV4x3ThsjtFzyGZ7Y2djTU8KqC3JL49USN+0w7bgAFtCGj4YqOR3z7e3NcdxZ49VCtZKFD3/d6zblbqepW5T8ht2PW2QSGb4nH7Nx+OeZuId2afogCoCFRHVQhMpHf6/IdnyaGGHqiwX+og81nEzGobTd42mGj4kdNBIwPAnpI3mACJLoHj75NB0ns10CRW1rWXxn0w1wzZmwA/TSjWGuieGpjSsvKcn/upoPmj6pDa7/I0jNVOhgSxjuqj/v98D995r7JkHPjOEkptZf37lWUeulS5Wh0HaQwErWb0K3huXX8ZdlUuJ1Xq9/V9eg0OxSSk6e/zsMuXxGLrf2yDKDr+Ev4ssCQgeZ2CaznRFfBs= admin@DESKTOP-9EEH9LJ

    EOT
    }
  }
}

variable "vm_count" {
  type    = list(string)
  default = ["vm3", "vm4"]
}

variable "image" {
  type    = list(string)
  default = ["centos-cloud/centos-7", "ubuntu-os-cloud/ubuntu-2004-lts"]
}

variable "scripts" {
  type    = list(string)
  default = ["./script.sh", "./startup.sh"]
}

variable "metadata_key" {
  type = list(any)
  default = [{
    enable-oslogin         = false
    block-project-ssh-keys = true
    ssh-keys               = <<EOT
    admin:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9xQdGKRGXZGPWpDzhFukeu9anyva+Q7XkhCJcs6SAlu8QeuzsYwMbYuNwQOFOPzEeK5G6UTbaBMJ3NMXTrc3QwkVL2Wi+hQoPGK/kGvazxWtnpSzWcrksnYWeMo8il3BY+pXSOkuq0Yd8WmW6o+yMEV4x3ThsjtFzyGZ7Y2djTU8KqC3JL49USN+0w7bgAFtCGj4YqOR3z7e3NcdxZ49VCtZKFD3/d6zblbqepW5T8ht2PW2QSGb4nH7Nx+OeZuId2afogCoCFRHVQhMpHf6/IdnyaGGHqiwX+og81nEzGobTd42mGj4kdNBIwPAnpI3mACJLoHj75NB0ns10CRW1rWXxn0w1wzZmwA/TSjWGuieGpjSsvKcn/upoPmj6pDa7/I0jNVOhgSxjuqj/v98D995r7JkHPjOEkptZf37lWUeulS5Wh0HaQwErWb0K3huXX8ZdlUuJ1Xq9/V9eg0OxSSk6e/zsMuXxGLrf2yDKDr+Ev4ssCQgeZ2CaznRFfBs= admin@DESKTOP-9EEH9LJ

    EOT
    },
    {
      enable-oslogin         = false
      block-project-ssh-keys = true
      ssh-keys               = <<EOT
    root:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9xQdGKRGXZGPWpDzhFukeu9anyva+Q7XkhCJcs6SAlu8QeuzsYwMbYuNwQOFOPzEeK5G6UTbaBMJ3NMXTrc3QwkVL2Wi+hQoPGK/kGvazxWtnpSzWcrksnYWeMo8il3BY+pXSOkuq0Yd8WmW6o+yMEV4x3ThsjtFzyGZ7Y2djTU8KqC3JL49USN+0w7bgAFtCGj4YqOR3z7e3NcdxZ49VCtZKFD3/d6zblbqepW5T8ht2PW2QSGb4nH7Nx+OeZuId2afogCoCFRHVQhMpHf6/IdnyaGGHqiwX+og81nEzGobTd42mGj4kdNBIwPAnpI3mACJLoHj75NB0ns10CRW1rWXxn0w1wzZmwA/TSjWGuieGpjSsvKcn/upoPmj6pDa7/I0jNVOhgSxjuqj/v98D995r7JkHPjOEkptZf37lWUeulS5Wh0HaQwErWb0K3huXX8ZdlUuJ1Xq9/V9eg0OxSSk6e/zsMuXxGLrf2yDKDr+Ev4ssCQgeZ2CaznRFfBs= admin@DESKTOP-9EEH9LJ

    EOT
  }]
}

variable "name_prefix" {
  type    = string
  default = "az"
}