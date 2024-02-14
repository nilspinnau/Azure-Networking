

variable "priority" {
  type = number
}

variable "policy_id" {
  type = string
}

variable "name" {
  type = string
}

variable "firewall_public_ips" {
  type = list(string)
}

variable "network_rule_collections" {
  type = map(object({
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

  default = null
}

variable "nat_rule_collections" {
  type = map(object({
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

  default = null
}

variable "application_rule_collections" {
  type = map(object({
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

  default = null
}