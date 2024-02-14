

variable "address_space" {
  type    = string
  default = "172.16.0.0/24"
}


variable "gateway_subnet_newbits" {
  type    = number
  default = 3
}

variable "default_subnet_newbits" {
  type    = number
  default = 4
}

variable "resource_prefix" {
  type = string
}

variable "asn_number" {
  default = 65515
  type    = number
}


variable "enable_bgp" {
  type    = bool
  default = false
}

variable "remote_address_space" {
  type    = string
  default = null
}

variable "active_directory" {
  type = object({
    domain_name  = optional(string, "")
    netbios_name = optional(string, "")
  })
  default = {
    domain_name  = ""
    netbios_name = ""
  }
  nullable = false
}