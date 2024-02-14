

locals {
  az_region        = "eastus"
  resource_postfix = "eastus-test-networkmanager"
}


locals {
  enable_bastion  = true
  enable_firewall = true
  enable_vpn      = true
}


resource "azurerm_resource_group" "hub" {
  name     = "rg-${local.resource_postfix}-hub"
  location = local.az_region
}

resource "azurerm_resource_group" "red" {
  name     = "rg-${local.resource_postfix}-red"
  location = local.az_region
}

resource "azurerm_resource_group" "blue" {
  name     = "rg-${local.resource_postfix}-blue"
  location = local.az_region
}

locals {

  firewall_subnet = local.enable_firewall == true ? {
    name                = "AzureFirewallSubnet"
    address_prefixes    = ["10.200.2.0/24"]
    service_endpoints   = []
    user_defined_routes = []
  } : null

  bastion_host_subnet = local.enable_bastion == true ? {
    name                = "AzureBastionSubnet"
    address_prefixes    = ["10.200.6.0/24"]
    service_endpoints   = []
    delegation          = null
    user_defined_routes = []
    enable_nsg          = false
  } : null

  vpn_subnet = local.enable_vpn == true ? {
    name                = "GatewaySubnet"
    address_prefixes    = ["10.200.3.0/24"]
    service_endpoints   = []
    user_defined_routes = []
  } : null

  subnets = [for subnet in [local.firewall_subnet, local.bastion_host_subnet, local.vpn_subnet] : subnet if subnet != null]
}

module "hub" {
  source              = "../../modules/network/vnet"
  resource_group_name = azurerm_resource_group.hub.name
  az_region           = local.az_region
  resource_postfix    = local.resource_postfix

  vnet_config = {
    address_space = "10.200.0.0/16"
    subnets       = local.subnets
    dns_zones     = []
  }
}

locals {
  default_firewall_route = local.enable_firewall ? {
    address_prefix         = "0.0.0.0/0"
    next_hop_in_ip_address = module.firewall.0.internal_ip
    name                   = "default-all-to-firewall"
    next_hop_type          = "VirtualAppliance"
  } : null

  spoke_routes = [for udr in [local.default_firewall_route] : udr if udr != null]
}

module "firewall" {
  source = "../../modules/network/firewall"
  count  = local.enable_firewall == true ? 1 : 0

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.hub.name
  resource_postfix    = local.resource_postfix


  subnet_id      = module.hub.subnets_by_name["AzureFirewallSubnet"].id
  sku_tier       = "Premium"
  sku_name       = "AZFW_VNet"
  virtual_hub_id = null

  rule_collection_groups = jsondecode(file("./firewall_rules.json"))
}


module "bastion" {
  source = "../../modules/network/bastion"
  count  = local.enable_bastion == true ? 1 : 0

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.hub.name
  resource_postfix    = local.resource_postfix

  subnet_id = module.hub.subnets_by_name["AzureBastionSubnet"].id
}


module "vpn" {
  source = "../../modules/network/vpn_gateway"
  count  = local.enable_vpn == true ? 1 : 0

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.hub.name
  resource_postfix    = local.resource_postfix

  subnet_id = module.hub.subnets_by_name["GatewaySubnet"].id

  log_analytics_workspace_id = null
  vpn_configuration = {
    active_active = false
    enable_bgp    = false
    sku           = "VpnGw1"
    vpn_type      = "RouteBased"
  }
  vpn_client_address_space = []
}

locals {
  red_vnets = [
    {
      name          = "red-0"
      address_space = "10.201.0.0/24"
      subnets = [{
        address_prefixes    = ["10.201.0.0/28"]
        name                = "default"
        delegation          = null
        enable_nsg          = true
        service_endpoints   = []
        user_defined_routes = local.spoke_routes
        network_rules = [
          {
            access                       = "Allow"
            destination_address_prefixes = null
            source_address_prefixes      = module.hub.subnets_by_name["AzureBastionSubnet"].address_prefixes
            direction                    = "Inbound"
            destination_port_ranges      = ["3389"]
            name                         = "AllowRDP"
            protocol                     = "Tcp"
          }
        ]
      }]
      dns_zones = []
    },
    {
      name          = "red-1"
      address_space = "10.201.1.0/24"
      subnets = [{
        address_prefixes    = ["10.201.1.0/28"]
        name                = "default"
        delegation          = null
        enable_nsg          = true
        service_endpoints   = []
        user_defined_routes = local.spoke_routes
        network_rules = [
          {
            access                       = "Allow"
            destination_address_prefixes = null
            source_address_prefixes      = module.hub.subnets_by_name["AzureBastionSubnet"].address_prefixes
            direction                    = "Inbound"
            destination_port_ranges      = ["3389"]
            name                         = "AllowRDP"
            protocol                     = "Tcp"
          }
        ]
      }]
      dns_zones = []
    }
  ]

  blue_vnets = [
    {
      name          = "blue-0"
      address_space = "10.201.2.0/24"
      subnets = [{
        address_prefixes    = ["10.201.2.0/28"]
        name                = "default"
        delegation          = null
        enable_nsg          = true
        service_endpoints   = []
        user_defined_routes = local.spoke_routes
        network_rules = [
          {
            access                       = "Allow"
            destination_address_prefixes = null
            source_address_prefixes      = module.hub.subnets_by_name["AzureBastionSubnet"].address_prefixes
            direction                    = "Inbound"
            destination_port_ranges      = ["3389"]
            name                         = "AllowRDP"
            protocol                     = "Tcp"
          }
        ]
      }]
      dns_zones = []
    },
    {
      name          = "blue-1"
      address_space = "10.201.3.0/24"
      subnets = [{
        address_prefixes    = ["10.201.3.0/28"]
        name                = "default"
        delegation          = null
        enable_nsg          = true
        service_endpoints   = []
        user_defined_routes = local.spoke_routes
        network_rules = [
          {
            access                       = "Allow"
            destination_address_prefixes = null
            source_address_prefixes      = module.hub.subnets_by_name["AzureBastionSubnet"].address_prefixes
            direction                    = "Inbound"
            destination_port_ranges      = ["3389"]
            name                         = "AllowRDP"
            protocol                     = "Tcp"
          }
        ]
      }]
      dns_zones = []
    }
  ]
}

module "red_vnets" {
  source = "../../modules/network/vnet"

  for_each = { for idx, vnet in local.red_vnets : idx => vnet }

  resource_group_name = azurerm_resource_group.red.name
  az_region           = local.az_region
  resource_postfix    = "${local.resource_postfix}-${each.value.name}"

  vnet_config = each.value

  depends_on = [module.vpn, module.firewall]
}

module "blue_vnets" {
  source = "../../modules/network/vnet"

  for_each = { for idx, vnet in local.blue_vnets : idx => vnet }

  resource_group_name = azurerm_resource_group.blue.name
  az_region           = local.az_region
  resource_postfix    = "${local.resource_postfix}-${each.value.name}"

  vnet_config = each.value

  depends_on = [module.vpn, module.firewall]
}


locals {
  blue_vnets_result = [for idx, blue_vnet in module.blue_vnets :
    { id : blue_vnet.id, name : local.blue_vnets[idx].name }
  ]
  red_vnets_result = [for idx, red_vnet in module.red_vnets :
    { id : red_vnet.id, name : local.red_vnets[idx].name }
  ]
}

module "virtual_network_manager" {
  source = "../../modules/network/virtual_network_manager"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.hub.name
  resource_postfix    = local.resource_postfix

  hub_vnet = {
    id = module.hub.id
  }

  admin_configs = [
    {
      az_region = local.az_region
      name      = "ac-${local.az_region}"

      rule_collection = {
        name = "${local.az_region}_default_rc"
        rules = [
          {
            name   = "test"
            action = "Deny"
            destination = {
              address_prefix      = "Internet"
              address_prefix_type = "ServiceTag"
            }
            destination_port_ranges = ["53"]
            direction               = "Outbound"
            priority                = 100
            protocol                = "Udp"
            source = {
              address_prefix      = "VirtualNetwork"
              address_prefix_type = "ServiceTag"
            }
          }
        ]
      }
    }
  ]

  network_groups = [
    {
      name               = "red"
      group_connectivity = "None"
      members            = local.red_vnets_result
      admin_config_name  = "ac-${local.az_region}"
    },
    {
      name               = "blue"
      group_connectivity = "DirectlyConnected"
      members            = local.blue_vnets_result
      admin_config_name  = "ac-${local.az_region}"
    }
  ]

  depends_on = [module.blue_vnets, module.red_vnets]
}


module "bluevms" {
  source = "../../modules/compute/vm"

  for_each = { for idx, vnet in local.blue_vnets : idx => vnet }

  az_region           = local.az_region
  resource_postfix    = "${local.az_region}-blue${each.key}"
  resource_group_name = azurerm_resource_group.blue.name

  subnet_id = one(module.blue_vnets[each.key].subnets).id
  vm_sku    = "Standard_B2s"
  vm_name   = "vmnetmanblue${each.key}"

  admin_username = ""
  admin_password = ""

  active_directory = null
  enable_asg       = false
  enable_public_ip = false
  extensions       = false
}

module "redvms" {
  source = "../../modules/compute/vm"

  for_each = { for idx, vnet in local.red_vnets : idx => vnet }

  az_region           = local.az_region
  resource_postfix    = "${local.az_region}-red${each.key}"
  resource_group_name = azurerm_resource_group.red.name

  subnet_id = one(module.red_vnets[each.key].subnets).id
  vm_sku    = "Standard_B2s"
  vm_name   = "vmnetmanred${each.key}"

  admin_username = ""
  admin_password = ""

  active_directory = null
  enable_asg       = false
  enable_public_ip = false
  extensions       = false
}