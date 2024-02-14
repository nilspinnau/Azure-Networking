resource "random_id" "server" {
  keepers = {
    azi_id = 1
  }

  byte_length = 8
}


resource "azurerm_traffic_manager_profile" "default" {
  name                   = random_id.server.hex
  resource_group_name    = var.resource_group_name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = random_id.server.hex
    ttl           = 5
  }

  traffic_view_enabled = true

  monitor_config {
    protocol                     = var.probe.protocol
    port                         = var.probe.port
    path                         = var.probe.protocol == "TCP" ? null : var.probe.path
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "default" {
  for_each           = { for backend in var.backends : backend.name => backend }
  name               = each.value.name
  profile_id         = azurerm_traffic_manager_profile.default.id
  priority           = each.value.priority
  target_resource_id = each.value.target_id

  enabled = true
}