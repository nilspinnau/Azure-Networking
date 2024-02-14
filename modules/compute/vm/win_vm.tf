
resource "azurerm_public_ip" "default" {
  count = var.enable_public_ip == true ? 1 : 0

  name                = "pip-${var.vm_name}-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  sku               = "Basic"
  allocation_method = "Dynamic"
}


resource "azurerm_application_security_group" "asg" {
  count = var.enable_asg == true ? 1 : 0

  name                = "asg-${var.vm_name}-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region
}

resource "azurerm_network_interface_application_security_group_association" "asg_association" {
  count                         = var.enable_asg == true ? 1 : 0
  application_security_group_id = azurerm_application_security_group.asg.0.id
  network_interface_id          = azurerm_network_interface.nic.id
}

resource "azurerm_network_interface" "nic" {

  name                = "nic-${var.vm_name}-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  enable_accelerated_networking = false

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    primary                       = true
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_public_ip == true ? azurerm_public_ip.default.0.id : null
  }
}

resource "azurerm_windows_virtual_machine" "win_vm" {

  name                = var.vm_name
  computer_name       = var.vm_name
  location            = var.az_region
  resource_group_name = var.resource_group_name
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  provision_vm_agent = true

  zone = null

  allow_extension_operations = true
  encryption_at_host_enabled = false

  size = var.vm_sku
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  winrm_listener {
    protocol = "Http"
  }

  os_disk {
    name                 = "osdisk-${var.vm_name}-${var.resource_postfix}"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_storage_type
    disk_size_gb         = var.os_disk_size
  }


  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = var.windows_os_version
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}


###################
# VM extensions, recommended to be deployed and configured by azure policy

resource "azurerm_virtual_machine_extension" "azure_monitor" {
  count = var.extensions == true ? 1 : 0

  name                       = "Microsoft.Azure.Monitor"
  virtual_machine_id         = azurerm_windows_virtual_machine.win_vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
}


resource "azurerm_virtual_machine_extension" "azure_network_watcher" {

  name                       = "Microsoft.Azure.NetworkWatcher"
  virtual_machine_id         = azurerm_windows_virtual_machine.win_vm.id
  publisher                  = "Microsoft.Azure.NetworkWatcher"
  type                       = "NetworkWatcherAgentWindows"
  type_handler_version       = "1.4"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
}
