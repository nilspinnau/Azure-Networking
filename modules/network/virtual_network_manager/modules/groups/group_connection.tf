
resource "azurerm_network_manager_network_group" "default" {

  name               = "nwm-network_group-${var.network_group.name}"
  network_manager_id = var.network_manager_id
}


resource "azurerm_network_manager_static_member" "example" {
  for_each = { for idx, member in var.network_group.members : idx => member }

  name                      = "${azurerm_network_manager_network_group.default.name}-member-${each.value.name}"
  network_group_id          = azurerm_network_manager_network_group.default.id
  target_virtual_network_id = each.value.id
}
