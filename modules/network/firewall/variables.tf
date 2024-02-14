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

variable "sku_tier" {
  type        = string
  description = "Firewall SKU."
  default     = "Premium" # Valid values are Standard and Premium
  validation {
    condition     = contains(["Standard", "Premium"], var.sku_tier)
    error_message = "The SKU must be one of the following: Standard, Premium"
  }
}

variable "subnet_id" {
  type    = string
  default = null
}

variable "virtual_hub_id" {
  type    = string
  default = null
}

variable "rule_collection_groups" {
  type = list(object({
    name     = string
    priority = number
    network_rule_collections = map(object({
      action   = optional(string, "Allow")
      priority = number
      rules = optional(map(object({
        protocols             = optional(list(string), ["TCP"])
        destination_ports     = list(string)
        source_addresses      = optional(list(string), null)
        source_ip_groups      = optional(list(string), null)
        destination_addresses = optional(list(string), null)
        destination_ip_groups = optional(list(string), null)
        destination_fqdns     = optional(list(string), null)
      })), null)
    }))
    application_rule_collections = map(object({
      action   = optional(string, "Allow")
      priority = number
      rules = optional(map(object({
        description = optional(string, null)

        protocols = list(object({
          type = optional(string, "Https")
          port = optional(number, 443)
        }))

        source_addresses      = optional(list(string), null)
        source_ip_groups      = optional(list(string), null)
        destination_addresses = optional(list(string), null)
        destination_urls      = optional(list(string), null)
        destination_fqdns     = optional(list(string), null)
        destination_fqdn_tags = optional(list(string), null)
        terminate_tls         = optional(bool, null)
        web_categories        = optional(list(string), null)
      })), null)
    }))
    nat_rule_collections = map(object({
      action   = optional(string, "Dnat")
      priority = number
      rules = map(object({
        protocols           = optional(list(string), ["TCP"])
        source_addresses    = optional(list(string), null)
        source_ip_groups    = optional(list(string), null)
        destination_address = string
        destination_port    = number
        translated_address  = optional(string, null)
        translated_fqdn     = optional(string, null)
        translated_port     = number
      }))
    }))
  }))
}


variable "sku_name" {
  type    = string
  default = "AZFW_VNet"
}

variable "dns_proxy" {
  type = object({
    enabled     = optional(bool, false)
    dns_servers = optional(list(string), [])
  })
  default = null
}


variable "log_analytics_workspace_id" {
  type     = string
  default  = ""
  nullable = true
}