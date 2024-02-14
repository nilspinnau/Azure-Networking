
output "vm_backend_configs" {
  value = [for idx in range(var.instance_count) : {
    vm_id                     = azurerm_linux_virtual_machine.vm[idx].id
    vm_name                   = azurerm_linux_virtual_machine.vm[idx].name
    nic_id                    = azurerm_network_interface.nic[idx].id
    nic_ip_configuration_name = azurerm_network_interface.nic[idx].ip_configuration.0.name
    public_ip                 = try(azurerm_public_ip.default[idx].id, null)
  }]
}