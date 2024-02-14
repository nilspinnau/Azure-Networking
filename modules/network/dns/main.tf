
resource "azurerm_private_dns_zone" "dns_zones" {
  for_each = { for dns_zone in var.dns_zones : dns_zone.name => dns_zone }

  name                = each.value.name
  resource_group_name = var.resource_group_name
}


# Create a Private DNS to VNET link
resource "azurerm_private_dns_zone_virtual_network_link" "default" {
  for_each = { for dns_zone in var.dns_zones : dns_zone.name => dns_zone }

  name                  = "link-${each.value.name}-${var.vnet.name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = var.vnet.id
  registration_enabled  = each.value.enable_auto_registration

  depends_on = [azurerm_private_dns_zone.dns_zones]
}
