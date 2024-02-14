resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-appgateways-diagnostic-settings"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

data "azurerm_monitor_diagnostic_categories" "agw" {
  resource_id = azurerm_application_gateway.default.id
}

resource "azurerm_monitor_diagnostic_setting" "agw" {
  name                           = "diagnostic_setting"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.agw.resource_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.id
  log_analytics_destination_type = "Dedicated"

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.agw.metrics
    content {
      category = metric.value
    }
  }

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.agw.log_category_types
    content {
      category = enabled_log.value
    }
  }
}