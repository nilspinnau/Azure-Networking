

output "dc_ip" {
  value = module.domain_controller.vm_private_ip
}

output "vpn_ip" {
  value = module.vpn.public_ip
}

output "vpn_id" {
  value = module.vpn.id
}

output "rg_name" {
  value = azurerm_resource_group.rg.name
}
