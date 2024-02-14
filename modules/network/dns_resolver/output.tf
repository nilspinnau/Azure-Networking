


output "inbound_endpoint_ips" {
  value = [for ip_config in azurerm_private_dns_resolver_inbound_endpoint.default.ip_configurations : ip_config.private_ip_address]
}


output "dns_forwarding_ruleset_id" {
  value = azurerm_private_dns_resolver_dns_forwarding_ruleset.default.id
}


output "dns_forwarding_ruleset_name" {
  value = azurerm_private_dns_resolver_dns_forwarding_ruleset.default.name
}