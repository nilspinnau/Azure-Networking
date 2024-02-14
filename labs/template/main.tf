
locals {
  az_region        = "eastus"
  resource_postfix = "eastus-test-lb"
}


resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_postfix}"
  location = local.az_region
}

module "loadbalancer" {
  source = "../../modules/network/loadbalancer"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name

  resource_postfix = local.resource_postfix

  health_probe = {
    path     = null
    protocol = "Tcp"
    port     = 80
  }

  loadbalancing_rules = [{
    frontend_port = 80
    backend_port  = 80
    name          = "Http_loadbalancing"
    protocol      = "Tcp"
  }]
}

module "vms" {

}

