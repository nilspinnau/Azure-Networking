

resource "azurerm_log_analytics_workspace" "law" {
  count = var.enable_diagnostics == true ? 1 : 0

  name                = "law-bst-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


data "azurerm_monitor_diagnostic_categories" "nic" {
  resource_id = azurerm_network_interface.nic.id
}

resource "azurerm_monitor_diagnostic_setting" "nic" {
  count = var.enable_diagnostics == true ? 1 : 0

  name                           = "diagnostic_setting"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.nic.resource_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.0.id
  log_analytics_destination_type = "Dedicated"

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.nic.metrics
    content {
      category = metric.value
    }
  }

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.nic.log_category_types
    content {
      category = enabled_log.value
    }
  }
}


data "azurerm_monitor_diagnostic_categories" "public_ip" {
  count = var.enable_public_ip == true ? 1 : 0

  resource_id = azurerm_public_ip.default.0.id
}

resource "azurerm_monitor_diagnostic_setting" "public_ip" {
  count = var.enable_public_ip == true && var.enable_diagnostics == true ? 1 : 0

  name                           = "diagnostic_setting"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.public_ip.0.resource_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.0.id
  log_analytics_destination_type = "Dedicated"

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.public_ip.0.metrics
    content {
      category = metric.value
    }
  }

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.public_ip.0.log_category_types
    content {
      category = enabled_log.value
    }
  }
}