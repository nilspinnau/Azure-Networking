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


variable "network_groups" {
  type = list(object({
    name               = string
    group_connectivity = optional(string, "DirectlyConnected")
    admin_config_name  = string
    members = list(object({
      name = string
      id   = string
    }))
  }))
}

variable "admin_configs" {
  type = list(object({
    az_region = string
    name      = string
    rule_collection = object({
      name = string
      rules = list(object({
        name                    = string
        action                  = string
        direction               = string
        priority                = string
        protocol                = string
        destination_port_ranges = list(string)
        source = object({
          address_prefix      = string
          address_prefix_type = string
        })
        destination = object({
          address_prefix      = string
          address_prefix_type = string
        })
      }))
    })
  }))
}

variable "hub_vnet" {
  type = object({
    id = string
  })
}