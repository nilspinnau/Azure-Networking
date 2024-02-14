
resource "azurerm_network_security_group" "nsg" {

  name                = "nsg-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name
}


# TODO:
# implement application security groups for traffic segmentation (we require less ip addresses)
# data "azurerm_resources" "application_security_groups" {
#   type                = "Microsoft.Network/"
#   resource_group_name = var.vnet_resource_group_name
# }

# data "azurerm_application_security_group" "asg" {
#   for_each = {
#     for subnet in var.subnets : subnet => subnet.name
#     if var.enable_nsg == true
#   }

#   name                = each.value.application_security_group
#   resource_group_name = var.resource_group_name
# }

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = {
    for k, subnet in var.vnet_config.subnets : k => subnet
  }

  subnet_id                 = azurerm_subnet.subnets[each.key].id # each.value.id
  network_security_group_id = one(azurerm_network_security_group.nsg[*].id)
}
