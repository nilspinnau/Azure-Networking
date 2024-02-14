

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name

  address_space = [
    var.vnet_config.address_space
  ]

  dns_servers = var.custom_dns_servers
}

resource "azurerm_subnet" "subnets" {
  for_each = { for k, subnet in var.vnet_config.subnets : k => subnet }

  name                = each.value.name
  resource_group_name = var.resource_group_name

  virtual_network_name = azurerm_virtual_network.vnet.name

  address_prefixes  = each.value.address_prefixes
  service_endpoints = each.value.service_endpoints

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [1] : []
    content {
      name = each.value.delegation.name
      service_delegation {
        name    = each.value.delegation.service_delegation.name
        actions = each.value.delegation.service_delegation.actions
      }
    }
  }
}


resource "azurerm_network_security_group" "default" {
  for_each = {
    for k, subnet in var.vnet_config.subnets : k => subnet
    if subnet.enable_nsg == true
  }

  location            = var.az_region
  resource_group_name = var.resource_group_name
  name                = "nsg-${var.vnet_config.subnets[each.key].name}-${var.resource_postfix}"

  dynamic "security_rule" {
    for_each = { for idx, rule in each.value.network_rules : idx => rule }
    iterator = rule
    content {
      name                         = rule.value.name
      access                       = rule.value.access
      direction                    = rule.value.direction
      priority                     = 1000 + rule.key
      protocol                     = rule.value.protocol
      source_port_range            = "*"
      source_address_prefixes      = coalesce(rule.value.source_address_prefixes, azurerm_subnet.subnets[each.key].address_prefixes)
      destination_address_prefixes = coalesce(rule.value.destination_address_prefixes, azurerm_subnet.subnets[each.key].address_prefixes)
      destination_port_ranges      = rule.value.destination_port_ranges
    }
  }
}


resource "azurerm_subnet_network_security_group_association" "default" {
  for_each = {
    for k, subnet in var.vnet_config.subnets : k => subnet
    if subnet.enable_nsg == true
  }

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.default[each.key].id
}


resource "azurerm_virtual_network_peering" "to_remote" {
  for_each = { for idx, peering in var.peering : idx => peering }

  name                = "peering-to-${each.value.remote.name}"
  resource_group_name = var.resource_group_name

  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = each.value.remote.id

  allow_forwarded_traffic      = each.value.local.allow_forwarded_traffic
  allow_gateway_transit        = each.value.local.allow_gateway_transit
  allow_virtual_network_access = each.value.local.allow_virtual_network_access
  use_remote_gateways          = each.value.local.use_remote_gateways
}


resource "azurerm_virtual_network_peering" "from_remote" {
  for_each = { for idx, peering in var.peering : idx => peering }

  name                = "peering-to-${azurerm_virtual_network.vnet.name}"
  resource_group_name = each.value.remote.resource_group_name

  virtual_network_name      = each.value.remote.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id

  allow_forwarded_traffic      = each.value.remote.allow_forwarded_traffic
  allow_gateway_transit        = each.value.remote.allow_gateway_transit
  allow_virtual_network_access = each.value.remote.allow_virtual_network_access
  use_remote_gateways          = each.value.remote.use_remote_gateways
}