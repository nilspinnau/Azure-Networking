


output "vpn_ips" {
  value = [for ip in azurerm_vpn_gateway.default.bgp_settings.0.instance_0_bgp_peering_address.0.tunnel_ips : ip]
}