resource "azurerm_public_ip" "default" {
  name                = "pip-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "default" {
  name                             = "rs-${var.resource_postfix}"
  resource_group_name              = var.resource_group_name
  location                         = var.az_region
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.default.id
  subnet_id                        = var.subnet_id
  branch_to_branch_traffic_enabled = var.enable_branch_to_branch_traffic
}