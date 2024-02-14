
data "azurerm_monitor_diagnostic_categories" "bst" {
  resource_id = azurerm_bastion_host.default.id
}

resource "azurerm_monitor_diagnostic_setting" "bst" {
  name                           = "diagnostic_setting"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.bst.resource_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.bst.metrics
    content {
      category = metric.value
    }
  }

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.bst.log_category_types
    content {
      category = enabled_log.value
    }
  }
}


data "azurerm_monitor_diagnostic_categories" "public_ip" {
  resource_id = azurerm_public_ip.default.id
}

resource "azurerm_monitor_diagnostic_setting" "public_ip" {
  name                           = "diagnostic_setting"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.public_ip.resource_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.public_ip.metrics
    content {
      category = metric.value
    }
  }

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.public_ip.log_category_types
    content {
      category = enabled_log.value
    }
  }
}