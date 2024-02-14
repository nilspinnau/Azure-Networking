

output "nic_id" {
  value = azurerm_network_interface.nic.id
}

output "vm_id" {
  value = azurerm_windows_virtual_machine.win_vm.id
}

output "vm_private_ip" {
  value = azurerm_network_interface.nic.ip_configuration.0.private_ip_address
}

output "vm" {
  value = azurerm_windows_virtual_machine.win_vm
}

output "nic" {
  value = azurerm_network_interface.nic
}

output "vm_backend_config" {
  value = {
    vm_id                     = azurerm_windows_virtual_machine.win_vm.id
    nic_id                    = azurerm_network_interface.nic.id
    nic_ip_configuration_name = azurerm_network_interface.nic.ip_configuration.0.name
  }
}