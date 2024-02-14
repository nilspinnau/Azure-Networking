

output "public_ip" {
  value = azurerm_public_ip.default.ip_address
}

output "id" {
  value = azurerm_virtual_network_gateway.default.id
}