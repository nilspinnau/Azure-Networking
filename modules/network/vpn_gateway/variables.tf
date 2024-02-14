
variable "az_region" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_postfix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vpn_client_address_space" {
  type = list(string)
}

variable "vpn_configuration" {
  type = object({
    active_active = optional(bool, false)
    enable_bgp    = optional(bool, false)
    sku           = optional(string, "Standard")
    vpn_type      = optional(string, "RouteBased")
    asn_number    = optional(number, 65515)
  })
}


variable "log_analytics_workspace_id" {
  type     = string
  nullable = false
}