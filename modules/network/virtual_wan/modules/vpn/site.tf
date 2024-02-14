resource "azurerm_vpn_gateway" "default" {
  name                = "vpn-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  virtual_hub_id      = var.virtual_hub_id

  dynamic "bgp_settings" {
    for_each = var.bgp.enable == true ? [1] : []
    content {
      asn         = var.bgp.asn
      peer_weight = 10
    }
  }
}


resource "azurerm_vpn_site" "default" {
  for_each = { for site in var.vpn_sites : site.name => site }

  name                = "default-vpn-site"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  virtual_wan_id      = var.virtual_wan_id

  address_cidrs = each.value.address_cidrs
  device_model  = "SomeModel"
  device_vendor = "SomeVendor"

  dynamic "link" {
    for_each = toset(each.value.vpn_links)
    iterator = link
    content {
      name          = link.value.name
      ip_address    = link.value.ip_address
      speed_in_mbps = link.value.speed_in_mbps
      provider_name = link.value.provider_name
    }
  }
}

resource "azurerm_vpn_gateway_connection" "default" {
  for_each = { for site in var.vpn_sites : site.name => site }

  name               = "con-to-site-${each.value.name}"
  vpn_gateway_id     = azurerm_vpn_gateway.default.id
  remote_vpn_site_id = azurerm_vpn_site.default[each.key].id

  dynamic "vpn_link" {
    for_each = { for idx, vpn_link in each.value.vpn_links : idx => vpn_link }
    iterator = link
    content {
      name             = link.value.name
      vpn_site_link_id = azurerm_vpn_site.default[each.key].link[link.key].id
      bgp_enabled      = link.value.enable_bgp
      shared_key       = link.value.shared_key
      dynamic "ipsec_policy" {
        for_each = link.value.ipsec_policy != null ? [link.value.ipsec_policy] : []
        iterator = policy
        content {
          dh_group                 = policy.value.dh_group
          encryption_algorithm     = policy.value.encryption_algorithm
          ike_encryption_algorithm = policy.value.ike_encryption_algorithm
          ike_integrity_algorithm  = policy.value.ike_integrity_algorithm
          integrity_algorithm      = policy.value.integrity_algorithm
          pfs_group                = policy.value.pfs_group
          sa_data_size_kb          = policy.value.sa_data_size_kb
          sa_lifetime_sec          = policy.value.sa_lifetime_sec
        }
      }
    }
  }
}
