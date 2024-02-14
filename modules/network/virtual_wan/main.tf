
resource "azurerm_virtual_wan" "default" {
  name                = "vwan-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  allow_branch_to_branch_traffic = true
  disable_vpn_encryption         = false
  type                           = var.wan_sku
}

resource "azurerm_virtual_hub" "hubs" {
  for_each = {
    for hub in var.hubs : hub.name => hub
  }

  name                = "hub-${each.value.name}"
  resource_group_name = var.resource_group_name
  location            = each.value.az_region
  virtual_wan_id      = azurerm_virtual_wan.default.id
  address_prefix      = each.value.address_prefix

  sku                    = var.wan_sku
  hub_routing_preference = each.value.hub_routing_preference
}

# locals {
#   helper_list = distinct(flatten(
#         [for n in var.spokes: [for t in split(",", n["az_region"]): t]]))

#   helper_map = flatten([
#              for k in local.helper_list:
#              [
#                for item in var.spokes: 
#                {"${k}" = item} if length(regexall(k, item["az_region"])) > 0
#              ]
#            ])

#   spokes_by_region = {for item in local.helper_map: keys(item)[0] => values(item)[0]...}
# }

module "firewall" {
  source = "../firewall"

  for_each = {
    for idx, hub in var.hubs : hub.name => hub
    if hub.enable_firewall == true
  }


  az_region           = var.az_region
  resource_group_name = var.resource_group_name
  resource_postfix    = "${each.value.name}-${var.resource_postfix}"

  subnet_id = null

  sku_name = "AZFW_Hub"

  rule_collection_groups = each.value.rule_collection_groups

  virtual_hub_id = azurerm_virtual_hub.hubs[each.key].id
}


module "vpn_gateway" {
  source = "./modules/vpn"

  for_each = {
    for idx, hub in var.hubs : hub.name => hub
    if hub.enable_vpn == true
  }

  az_region           = var.az_region
  resource_group_name = var.resource_group_name
  virtual_hub_id      = azurerm_virtual_hub.hubs[each.key].id
  virtual_wan_id      = azurerm_virtual_wan.default.id

  resource_postfix = "${var.az_region}-${each.value.name}"

  vpn_sites = each.value.remote_sites

  bgp = {
    enable = each.value.enable_bgp
    asn    = each.value.vpn_gw_asn
  }

  p2s_ipsec_policy = null
  enable_p2s       = true
}


locals {
  hubs_by_name = { for idx, hub in var.hubs : hub.name => azurerm_virtual_hub.hubs[hub.name] }
}

locals {
  route_table_by_name = { for idx, route_table in azurerm_virtual_hub_route_table.default : route_table.name => route_table }
}

resource "azurerm_virtual_hub_route_table" "default" {
  for_each = { for route_table in var.route_tables : route_table.name => route_table }

  name           = each.value.name
  virtual_hub_id = local.hubs_by_name[each.value.hub_name].id

  dynamic "route" {
    for_each = toset(each.value.routes)
    iterator = route
    content {
      name              = route.value.name
      destinations_type = route.value.destinations_type
      destinations      = route.value.destinations
      next_hop_type     = route.value.next_hop_type
      next_hop          = route.value.next_hop == "firewall" ? module.firewall[each.value.hub_name].id : route.value.next_hop
    }
  }
}
