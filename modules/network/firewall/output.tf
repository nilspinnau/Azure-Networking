

output "internal_ip" {
  value = var.virtual_hub_id != null ? azurerm_firewall.fw.virtual_hub.0.private_ip_address : azurerm_firewall.fw.ip_configuration.0.private_ip_address
}

output "id" {
  value = azurerm_firewall.fw.id
}