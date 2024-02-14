
resource "azurerm_log_analytics_workspace" "default" {
  name                = "law-conmon-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
}

data "azurerm_network_watcher" "netwat" {
  name                = "NetworkWatcher_${var.az_region}"
  resource_group_name = "NetworkWatcherRG"
}

data "azurerm_monitor_action_group" "agowner" {
  name                = "AGOwner"
  resource_group_name = "Default-ActivityLogAlerts"
}

resource "azurerm_network_connection_monitor" "default" {
  name               = "conmon-${var.resource_postfix}"
  network_watcher_id = data.azurerm_network_watcher.netwat.id
  location           = var.az_region

  dynamic "endpoint" {
    for_each = { for endpoint in var.endpoints : endpoint.name => endpoint }
    iterator = endpoint
    content {
      name               = endpoint.value.name
      target_resource_id = endpoint.value.resource_id
      address            = endpoint.value.ip_address
    }
  }

  dynamic "test_configuration" {
    for_each = { for config in var.test_configurations : config.name => config }
    iterator = config
    content {
      name                      = config.value.name
      protocol                  = config.value.protocol
      test_frequency_in_seconds = config.value.test_frequency_in_seconds

      tcp_configuration {
        port = 3389
      }

      # http_configuration {
      #   method = "Get"
      #   path = "/"
      #   port = 80
      #   valid_status_code_ranges = ["200"]
      # }

      # icmp_configuration {
      #   trace_route_enabled = false
      # }
    }
  }

  dynamic "test_group" {
    for_each = { for test_group in var.test_groups : test_group.name => test_group }
    iterator = test_group
    content {
      name                     = test_group.value.name
      destination_endpoints    = test_group.value.destinations
      source_endpoints         = test_group.value.sources
      test_configuration_names = test_group.value.test_configuration_names
    }
  }

  output_workspace_resource_ids = [azurerm_log_analytics_workspace.default.id]

}