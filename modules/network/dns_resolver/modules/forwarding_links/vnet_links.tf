


resource "azurerm_private_dns_resolver_virtual_network_link" "default" {
  for_each = { for vnet in var.linked_vnets : vnet.id => vnet }

  name                      = "link-to-dsr-${each.value.name}-${var.dns_forwarding_ruleset_name}"
  dns_forwarding_ruleset_id = var.dns_forwarding_ruleset_id
  virtual_network_id        = each.value.id
}