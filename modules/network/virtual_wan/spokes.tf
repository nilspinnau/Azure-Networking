resource "azurerm_virtual_network" "spoke" {
  for_each = {
    for idx, spoke in var.spokes : spoke.name => spoke
  }

  name                = "vnet-${each.value.az_region}-spoke-${each.value.name}"
  location            = each.value.az_region
  resource_group_name = each.value.resource_group_name

  address_space = each.value.address_space

  subnet = each.value.subnets
}


resource "azurerm_virtual_hub_connection" "spoke_connection" {
  for_each = {
    for idx, spoke in var.spokes : spoke.name => spoke
  }

  name = "con-${each.value.hub_name}-to-${azurerm_virtual_network.spoke[each.key].name}"

  remote_virtual_network_id = azurerm_virtual_network.spoke[each.key].id
  virtual_hub_id            = local.hubs_by_name[each.value.hub_name].id

  routing {
    associated_route_table_id = local.route_table_by_name[each.value.route_table_name].id
    propagated_route_table {
      labels          = each.value.propagated_labels
      route_table_ids = each.value.propagate_itself == true ? [local.route_table_by_name[each.value.route_table_name].id] : []
    }
  }
  internet_security_enabled = true
}