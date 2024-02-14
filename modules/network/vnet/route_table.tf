

module "route_tables" {
  source = "./modules/route_table"

  for_each = {
    for k, subnet in var.vnet_config.subnets : k => subnet
    if length(subnet.user_defined_routes) > 0
  }

  az_region           = var.az_region
  resource_group_name = var.resource_group_name
  resource_postfix    = var.resource_postfix
  subnet_id           = azurerm_subnet.subnets[each.key].id
  user_defined_routes = each.value.user_defined_routes
}