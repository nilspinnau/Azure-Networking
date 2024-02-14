variable "az_region" {
  type = string
}

variable "resource_postfix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "wan_sku" {
  type    = string
  default = "Standard"
}


variable "hubs" {
  type = list(object({
    name                   = string
    az_region              = string
    address_prefix         = string
    hub_routing_preference = string
    enable_vpn             = optional(bool, false)
    enable_er              = optional(bool, false)
    enable_firewall        = optional(bool, true)
    vpn_gw_asn             = optional(number, 65515)
    enable_bgp             = optional(bool, false)
    remote_sites = list(object({
      name          = string
      address_cidrs = list(string)
      vpn_links = list(object({
        name          = string
        enable_bgp    = bool
        ip_address    = string
        speed_in_mbps = number
        provider_name = string
        shared_key    = string
        ipsec_policy = optional(object({
          dh_group                 = string
          encryption_algorithm     = string
          ike_encryption_algorithm = string
          ike_integrity_algorithm  = string
          integrity_algorithm      = string
          pfs_group                = string
          sa_data_size_kb          = string
          sa_lifetime_sec          = string
        }), null)
      }))
    }))
    rule_collection_groups = list(object({
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
  }))
}

variable "spokes" {
  type = list(object({
    name                = string
    az_region           = string
    address_space       = list(string)
    hub_name            = string
    route_table_name    = string
    propagate_itself    = bool
    propagated_labels   = list(string)
    resource_group_name = string
    subnets = list(object({
      address_prefix = string
      id             = string
      name           = string
      security_group = string
    }))
  }))
}


variable "route_tables" {
  type = list(object({
    name     = string
    hub_name = string
    routes = list(object({
      name              = string
      next_hop          = string
      next_hop_type     = string
      destinations      = list(string)
      destinations_type = string
    }))
  }))
}