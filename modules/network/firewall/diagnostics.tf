resource "azurerm_log_analytics_workspace" "law" {
  name                = "firewall-log-analytics-workspace"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

data "azurerm_monitor_diagnostic_categories" "fw" {
  resource_id = azurerm_firewall.fw.id
}

resource "azurerm_monitor_diagnostic_setting" "fw" {
  name                           = "diagnostic_setting"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.fw.resource_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.id
  log_analytics_destination_type = "Dedicated"

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.fw.metrics
    content {
      category = metric.value
    }
  }

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.fw.log_category_types
    content {
      category = enabled_log.value
    }
  }
}


data "azurerm_monitor_diagnostic_categories" "public_ip" {
  count       = var.sku_name != "AZFW_Hub" ? 1 : 0
  resource_id = azurerm_public_ip.pip_afw.0.id
}

resource "azurerm_monitor_diagnostic_setting" "public_ip" {
  count                          = var.sku_name != "AZFW_Hub" ? 1 : 0
  name                           = "diagnostic_setting"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.public_ip.0.resource_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.id
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


data "azurerm_monitor_diagnostic_categories" "public_ip_2" {
  count       = var.sku_name != "AZFW_Hub" ? 1 : 0
  resource_id = azurerm_public_ip.pip_afw_2.0.id
}

resource "azurerm_monitor_diagnostic_setting" "public_ip_2" {
  count                          = var.sku_name != "AZFW_Hub" ? 1 : 0
  name                           = "diagnostic_setting"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.public_ip_2.0.resource_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.id
  log_analytics_destination_type = "Dedicated"

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.public_ip_2.0.metrics
    content {
      category = metric.value
    }
  }

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.public_ip_2.0.log_category_types
    content {
      category = enabled_log.value
    }
  }
}