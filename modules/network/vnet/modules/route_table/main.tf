
resource "azurerm_route_table" "route_table" {
  name                = "rt-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name

  disable_bgp_route_propagation = true
}

resource "azurerm_route" "udrs" {
  for_each = {
    for k, route in var.user_defined_routes : k => route
  }
  name                = each.value.name
  route_table_name    = azurerm_route_table.route_table.name
  resource_group_name = azurerm_route_table.route_table.resource_group_name

  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}



resource "azurerm_subnet_route_table_association" "subnet_route_table_association" {
  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.route_table.id
}
