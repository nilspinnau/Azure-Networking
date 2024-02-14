

output "zone_ids" {
  value = [for zone in azurerm_private_dns_zone.dns_zones : zone.id]
}