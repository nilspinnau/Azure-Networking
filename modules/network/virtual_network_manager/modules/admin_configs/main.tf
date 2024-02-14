
resource "azurerm_network_manager_security_admin_configuration" "default" {

  name               = "nw-admin_config-${var.az_region}"
  network_manager_id = var.network_manager_id
}

resource "azurerm_network_manager_admin_rule_collection" "default" {
  name                            = var.admin_config.name
  security_admin_configuration_id = azurerm_network_manager_security_admin_configuration.default.id
  network_group_ids               = var.network_group_ids
  # network_group_ids               = [azurerm_network_manager_network_group.default.id]
}

resource "azurerm_network_manager_admin_rule" "default" {
  for_each = { for idx, rule in var.admin_config.rule_collection.rules : idx => rule }

  admin_rule_collection_id = azurerm_network_manager_admin_rule_collection.default.id

  name      = each.value.name
  action    = each.value.action
  direction = each.value.direction

  priority = each.value.priority
  protocol = each.value.protocol

  destination_port_ranges = each.value.destination_port_ranges
  source {
    address_prefix      = each.value.source.address_prefix
    address_prefix_type = each.value.source.address_prefix_type
  }

  destination {
    address_prefix      = each.value.destination.address_prefix
    address_prefix_type = each.value.destination.address_prefix_type
  }
}
