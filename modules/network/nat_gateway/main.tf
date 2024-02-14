resource "azurerm_public_ip" "default" {
  name                = "pip-nat-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "default" {
  name                    = "nat-${var.resource_postfix}"
  location                = var.az_region
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = null
}

resource "azurerm_nat_gateway_public_ip_association" "default" {
  nat_gateway_id       = azurerm_nat_gateway.default.id
  public_ip_address_id = azurerm_public_ip.default.id
}

resource "azurerm_subnet_nat_gateway_association" "default" {
  for_each = toset(var.subnet_ids)

  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.default.id
}