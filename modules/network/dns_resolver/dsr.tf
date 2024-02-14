resource "azurerm_private_dns_resolver" "default" {
  name                = "dsr-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region
  virtual_network_id  = var.vnet_id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "default" {
  name                    = "inbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.default.id
  location                = var.az_region
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = var.inbound_subnet_id
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "default" {
  name                    = "outbound-endpoint"
  private_dns_resolver_id = azurerm_private_dns_resolver.default.id
  location                = var.az_region
  subnet_id               = var.outbound_subnet_id
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "default" {
  name                                       = "default-ruleset"
  resource_group_name                        = var.resource_group_name
  location                                   = var.az_region
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.default.id]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "forwarding_rules" {
  for_each = { for forwarding_rule in var.forwarding_rules : forwarding_rule.domain_name => forwarding_rule }

  name = "rule_${each.value.rule_name}"

  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.default.id
  domain_name               = each.value.domain_name

  dynamic "target_dns_servers" {
    for_each = { for dns_server in each.value.dns_servers : dns_server.ip_address => dns_server }
    iterator = dns_server
    content {
      ip_address = dns_server.value.ip_address
      port       = 53
    }
  }
}