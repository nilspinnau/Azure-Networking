variable "az_region" {
  type = string
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the network security group into."
}

variable "resource_postfix" {
  type = string
}

variable "vnet_config" {
  type = object({
    address_space = string
    subnets = list(object({
      name              = string
      address_prefixes  = list(string)
      service_endpoints = list(string)
      enable_nsg        = optional(bool, false)
      user_defined_routes = optional(list(object({
        name                   = string
        address_prefix         = string
        next_hop_type          = string
        next_hop_in_ip_address = optional(string, null)
      })), [])
      delegation = optional(object({
        name = string
        service_delegation = object({
          name    = string
          actions = list(string)
        })
      }), null)
      network_rules = optional(list(object({
        name                         = string
        protocol                     = optional(string, "Tcp")
        access                       = optional(string, "Allow")
        direction                    = optional(string, "Inbound")
        destination_port_ranges      = optional(list(string), ["*"])
        source_address_prefixes      = optional(list(string), null)
        destination_address_prefixes = optional(list(string), null)
      })), [])
    }))
    dns_zones = list(object({
      name                     = string
      enable_auto_registration = bool
    }))
  })
}


variable "peering" {
  type = list(object({
    remote = object({
      id                           = string
      name                         = string
      resource_group_name          = string
      allow_virtual_network_access = optional(bool, true)
      allow_gateway_transit        = optional(bool, false)
      allow_forwarded_traffic      = optional(bool, false)
      use_remote_gateways          = optional(bool, false)
    })
    local = object({
      allow_virtual_network_access = optional(bool, true)
      allow_gateway_transit        = optional(bool, false)
      allow_forwarded_traffic      = optional(bool, false)
      use_remote_gateways          = optional(bool, false)
    })
  }))
  default = []
}

variable "enable_flow_log" {
  default = false
  type    = bool
}

variable "custom_dns_servers" {
  type    = list(string)
  default = []
}