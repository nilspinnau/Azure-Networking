
data "azurerm_subscription" "current" {
}

resource "azurerm_network_manager" "default" {
  name                = "nm-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  scope {
    subscription_ids = [data.azurerm_subscription.current.id]
  }
  scope_accesses = ["Connectivity", "SecurityAdmin"]
}

module "network_groups" {
  source = "./modules/groups"

  for_each = { for idx, group in var.network_groups : idx => group }

  network_group      = each.value
  network_manager_id = azurerm_network_manager.default.id
}

resource "azurerm_network_manager_connectivity_configuration" "default" {
  for_each = { for idx, group in var.network_groups : idx => group }

  name                  = "conf-connectivity-${each.value.name}"
  network_manager_id    = azurerm_network_manager.default.id
  connectivity_topology = "HubAndSpoke"


  applies_to_group {
    group_connectivity = each.value.group_connectivity
    network_group_id   = module.network_groups[each.key].network_group_id
    use_hub_gateway    = true
  }

  hub {
    resource_id   = var.hub_vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
}

resource "azurerm_network_manager_deployment" "connectivity" {

  network_manager_id = azurerm_network_manager.default.id
  location           = var.az_region
  scope_access       = "Connectivity"
  configuration_ids = [
  for idx, group in var.network_groups : azurerm_network_manager_connectivity_configuration.default[idx].id]
}

