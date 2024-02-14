resource "azurerm_public_ip_prefix" "pip_prefix" {
  count = var.sku_name != "AZFW_Hub" ? 1 : 0

  name                = "pip-prefix-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  prefix_length       = 31
}

resource "azurerm_public_ip" "pip_afw" {
  count               = var.sku_name != "AZFW_Hub" ? 1 : 0
  name                = "pip-afw-${var.resource_postfix}-001"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  allocation_method   = "Static"
  public_ip_prefix_id = azurerm_public_ip_prefix.pip_prefix.0.id
}

resource "azurerm_public_ip" "pip_afw_2" {
  count               = var.sku_name != "AZFW_Hub" ? 1 : 0
  name                = "pip-afw-${var.resource_postfix}-002"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  allocation_method   = "Static"
  public_ip_prefix_id = azurerm_public_ip_prefix.pip_prefix.0.id
}

resource "azurerm_firewall" "fw" {
  name                = "afw-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name

  sku_name = var.sku_name
  sku_tier = var.sku_tier

  dynamic "ip_configuration" {
    for_each = var.subnet_id != null ? [azurerm_public_ip.pip_afw.0.id] : []
    iterator = fw_ip
    content {
      name                 = "afw-ipconfig"
      subnet_id            = var.subnet_id
      public_ip_address_id = fw_ip.value
    }
  }

  dynamic "ip_configuration" {
    for_each = var.subnet_id != null ? [azurerm_public_ip.pip_afw_2.0.id] : []
    iterator = fw_ip
    content {
      name                 = "afw-ipconfig2"
      subnet_id            = null
      public_ip_address_id = fw_ip.value
    }
  }

  dynamic "virtual_hub" {
    for_each = var.virtual_hub_id != null ? [1] : []
    content {
      virtual_hub_id  = var.virtual_hub_id
      public_ip_count = 1
    }
  }

  firewall_policy_id = azurerm_firewall_policy.afw_policy.id
}