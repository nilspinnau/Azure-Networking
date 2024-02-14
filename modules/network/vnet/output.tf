

output "subnets" {
  value = [for subnet in azurerm_subnet.subnets : {
    id : subnet.id
    name : subnet.name
  }]
}

output "subnets_by_name" {
  value = { for subnet in azurerm_subnet.subnets : subnet.name => subnet }
}

output "dns_zones" {
  value = [for dns_zone in azurerm_private_dns_zone.dns_zones : {
    zone_name = dns_zone.name
    zone_id   = dns_zone.id
    # vnet_link = "link-${each.value.name}-local"
  }]
}

output "vnet" {
  value = {
    id : azurerm_virtual_network.vnet.id
    name : azurerm_virtual_network.vnet.name
  }
}

output "name" {
  value = azurerm_virtual_network.vnet.name
}
output "id" {
  value = azurerm_virtual_network.vnet.id
}