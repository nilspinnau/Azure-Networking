
variable "az_region" {
  type = string
}

variable "network_manager_id" {
  type = string
}

variable "network_group_ids" {
  type = list(string)
}

variable "admin_config" {
  type = object({
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
  })
}