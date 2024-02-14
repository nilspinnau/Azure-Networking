

locals {
  az_region        = "eastus"
  resource_postfix = "eastus-test-${var.resource_prefix}-onprem"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_postfix}"
  location = local.az_region
}

locals {
  subnets = cidrsubnets(var.address_space, var.default_subnet_newbits, var.gateway_subnet_newbits)
}

module "onprem_network" {
  source              = "../../modules/network/vnet"
  az_region           = local.az_region
  resource_postfix    = local.resource_postfix
  resource_group_name = azurerm_resource_group.rg.name

  vnet_config = {
    address_space = var.address_space
    subnets = [{
      address_prefixes    = [local.subnets[0]]
      name                = "default"
      delegation          = null
      service_endpoints   = []
      user_defined_routes = [],
      },
      {
        name                = "GatewaySubnet"
        address_prefixes    = [local.subnets[1]]
        delegation          = null
        service_endpoints   = []
        user_defined_routes = []
    }]
    dns_zones = []
  }
}

module "vpn" {
  source = "../../modules/network/vpn_gateway"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  subnet_id = module.onprem_network.subnets_by_name["GatewaySubnet"].id

  vpn_configuration = {
    active_active = false
    enable_bgp    = var.enable_bgp
    sku           = "VpnGw1"
    vpn_type      = "RouteBased"
    asn_number    = var.asn_number
  }
  # we do not enable p2s for onprem gateway
  vpn_client_address_space   = []
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}


resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-bst-${local.resource_postfix}"
  location            = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


module "domain_controller" {
  source = "../../modules/compute/vm"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  admin_username = ""
  admin_password = ""

  vm_sku = "Standard_B2s"

  subnet_id = module.onprem_network.subnets_by_name["default"].id

  data_disks = []

  vm_name = "dc1"

  enable_public_ip = false

  active_directory = {
    domain_name  = var.active_directory.domain_name
    netbios_name = var.active_directory.netbios_name
  }
}


# resource "azurerm_route_table" "route_to_azure" {
#   count = var.enable_bgp == false ? 1 : 0

#   name                = "rt-${local.resource_postfix}-to_azure"
#   location            = local.az_region
#   resource_group_name = azurerm_resource_group.rg.name

#   disable_bgp_route_propagation = false

#   route = [
#     {
#     name                   = "all_else_to_gateway"
#     address_prefix         = "0.0.0.0/0"
#     next_hop_type          = "VirtualNetworkGateway"
#     next_hop_in_ip_address = null
#     },
#     {
#       name                   = "azure_range_to_gateway"
#       address_prefix         = var.remote_address_space
#       next_hop_type          = "VirtualNetworkGateway"
#       next_hop_in_ip_address = null
#     }
#   ]
# }

# resource "azurerm_subnet_route_table_association" "vpn_to_firewall" {
#   count = var.enable_bgp == false ? 1 : 0

#   route_table_id = azurerm_route_table.route_to_azure.0.id
#   subnet_id      = module.onprem_network.subnets_by_name["default"].id
# }