

variable "virtual_hub_id" {
  type = string
}

variable "virtual_wan_id" {
  type = string
}


variable "resource_postfix" {
  type = string
}

variable "az_region" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "bgp" {
  type = object({
    asn    = optional(number, 65515)
    enable = optional(bool, false)
  })
  nullable = false
}

variable "vpn_sites" {
  type = list(object({
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
}

variable "enable_p2s" {
  type    = bool
  default = true
}

variable "p2s_ipsec_policy" {
  type = object({
    dh_group                 = string
    encryption_algorithm     = string
    ike_encryption_algorithm = string
    ike_integrity_algorithm  = string
    integrity_algorithm      = string
    pfs_group                = string
    sa_data_size_kb          = string
    sa_lifetime_sec          = string
  })
  nullable = true
}