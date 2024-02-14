

module "admin_configs" {
  source   = "./modules/admin_configs"
  for_each = { for idx, admin_config in var.admin_configs : idx => admin_config }

  admin_config = each.value

  az_region = each.value.az_region

  network_group_ids  = [for idx, group in var.network_groups : module.network_groups[idx].network_group_id if group.admin_config_name == each.value.name]
  network_manager_id = azurerm_network_manager.default.id
}


resource "azurerm_network_manager_deployment" "admin_rules" {
  for_each = { for idx, admin_config in var.admin_configs : idx => admin_config }

  network_manager_id = azurerm_network_manager.default.id
  location           = var.az_region
  scope_access       = "SecurityAdmin"
  configuration_ids  = [module.admin_configs[each.key].id]
}
