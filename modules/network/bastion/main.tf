resource "azurerm_public_ip" "default" {
  name                = "pip-bst-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "default" {
  name                = "bst-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "default_config"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.default.id
  }

  copy_paste_enabled     = true
  file_copy_enabled      = var.sku == "Standard" ? true : false
  ip_connect_enabled     = var.sku == "Standard" ? true : false
  shareable_link_enabled = var.sku == "Standard" ? true : false
  tunneling_enabled      = var.sku == "Standard" ? true : false
  sku                    = var.sku
}