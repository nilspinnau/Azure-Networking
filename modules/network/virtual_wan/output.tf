

# output "spokes_by_name" {
#   value = { for idx, spoke in azurerm_virtual_network.spoke : var.spokes[idx].name => spoke }  
# }


output "spokes_by_id" {
  value = { for idx, spoke in azurerm_virtual_network.spoke : idx => spoke }
}

output "vpn_ips" {
  value = [for idx, hub in var.hubs : module.vpn_gateway[hub.name].vpn_ips if hub.enable_vpn == true]
}