
resource "azurerm_public_ip" "default" {
  count = var.enable_public_ip == true ? var.instance_count : 0

  name                = "pip-${var.vm_name}${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  domain_name_label = "${var.vm_name}${count.index}"

  sku               = "Basic"
  allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "nic" {

  count = var.instance_count

  name                = "nic-${var.vm_name}${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  enable_accelerated_networking = false

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    primary                       = true
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.enable_public_ip == true ? azurerm_public_ip.default[count.index].id : null
  }

  depends_on = [azurerm_public_ip.default]
}


resource "azurerm_linux_virtual_machine" "vm" {
  count = var.instance_count

  name                  = "${var.vm_name}${count.index}"
  location              = var.az_region
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size                  = var.vm_sku

  os_disk {
    name                 = "osdisk-${var.vm_name}${count.index}"
    caching              = "ReadWrite"
    disk_size_gb         = var.os_disk_size
    storage_account_type = var.os_disk_storage_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
}


resource "azurerm_virtual_machine_extension" "my_vm_extension" {
  count = var.instance_count

  name                 = "Nginx"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm[count.index].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
 {
  "commandToExecute": "sudo apt-get update && sudo apt-get install nginx -y && echo \"Hello World from $(hostname)\" > /var/www/html/index.html && sudo systemctl restart nginx"
 }
SETTINGS

}