
resource "azurerm_firewall_policy" "afw_policy" {
  name                = "afwp-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  sku                      = var.sku_tier
  threat_intelligence_mode = "Deny"

  insights {
    default_log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
    enabled                            = true
    retention_in_days                  = 30
  }

  dynamic "intrusion_detection" {
    for_each = var.sku_tier == "Premium" ? [1] : []
    content {
      mode = "Deny"
    }
  }

  dns {
    proxy_enabled = try(var.dns_proxy.enabled, false)
    servers       = try(distinct(concat(var.dns_proxy.dns_servers, ["168.63.129.16"])), null)
  }
}


module "rc_groups" {
  source = "./modules/rc_groups"

  for_each = { for idx, rc_group in var.rule_collection_groups : idx => rc_group }

  name                         = each.value.name
  application_rule_collections = each.value.application_rule_collections
  nat_rule_collections         = each.value.nat_rule_collections
  network_rule_collections     = each.value.network_rule_collections

  priority  = each.value.priority
  policy_id = azurerm_firewall_policy.afw_policy.id

  firewall_public_ips = var.virtual_hub_id != null ? azurerm_firewall.fw.virtual_hub.0.public_ip_addresses : [azurerm_public_ip.pip_afw.0.ip_address]
}