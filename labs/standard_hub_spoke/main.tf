

locals {
  az_region        = "eastus"
  resource_postfix = "eastus-test"
}

locals {
  enable_bgp = true
}

locals {
  active_directory = {
    domain_name  = ""
    netbios_name = ""
  }
}

locals {
  enable_bastion      = true
  enable_dns_resolver = true
  enable_er           = false
  enable_firewall     = true
  enable_route_server = false
  enable_vpn          = true
}


locals {
  # normal public access
  enable_private_endpoint      = false
  enable_service_endpoint      = false
  enable_public_network_access = true

  # service endpoint
  # enable_private_endpoint      = false
  # enable_service_endpoint      = true
  # enable_public_network_access = true


  # private endpoint
  # enable_private_endpoint      = true
  # enable_service_endpoint      = false
  # enable_public_network_access = false
}

resource "azurerm_resource_group" "hub" {
  name     = "rg-${local.resource_postfix}-hub"
  location = local.az_region
}

resource "azurerm_resource_group" "east" {
  name     = "rg-${local.resource_postfix}-east"
  location = local.az_region
}

resource "azurerm_resource_group" "west" {
  name     = "rg-${local.resource_postfix}-west"
  location = local.az_region
}


resource "azurerm_resource_group" "dns" {
  name     = "rg-${local.resource_postfix}-dns"
  location = local.az_region
}

locals {
  route_server_subnet = local.enable_route_server == true ? {
    name                = "RouteServerSubnet"
    address_prefixes    = ["10.0.1.0/24"]
    service_endpoints   = []
    user_defined_routes = []
  } : null

  firewall_subnet = local.enable_firewall == true ? {
    name                = "AzureFirewallSubnet"
    address_prefixes    = ["10.0.2.0/24"]
    service_endpoints   = []
    user_defined_routes = []
  } : null

  vpn_subnet = local.enable_vpn == true ? {
    name                = "GatewaySubnet"
    address_prefixes    = ["10.0.3.0/24"]
    service_endpoints   = []
    user_defined_routes = []
  } : null

  dns_resolver_inbound_subnet = local.enable_dns_resolver == true ? {
    name              = "DNSResolverInbound"
    address_prefixes  = ["10.0.4.0/24"]
    service_endpoints = []
    enable_nsg        = true
    network_rules = [
      {
        name                         = "allow_dns_inbound"
        protocol                     = "Udp"
        access                       = "Allow"
        destination_port_ranges      = ["53"]
        source_address_prefixes      = ["0.0.0.0/0"]
        destination_address_prefixes = null
        direction                    = "Inbound"
      },
      {
        name                         = "deny_all_inbound"
        protocol                     = "*"
        access                       = "Deny"
        destination_port_ranges      = ["0-65535"]
        source_address_prefixes      = ["0.0.0.0/0"]
        destination_address_prefixes = ["0.0.0.0/0"]
        direction                    = "Inbound"
      },
      {
        name                         = "deny_all_outbound"
        protocol                     = "Tcp"
        access                       = "Allow"
        destination_port_ranges      = ["0-65535"]
        source_address_prefixes      = ["0.0.0.0/0"]
        destination_address_prefixes = ["0.0.0.0/0"]
        direction                    = "Outbound"
      }
    ]
    delegation = {
      name = "Microsoft.Network.dnsResolvers"
      service_delegation = {
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        name    = "Microsoft.Network/dnsResolvers"
      }
    }
    user_defined_routes = []
  } : null
  dns_resolver_outbound_subnet = local.enable_dns_resolver == true ? {
    name              = "DNSResolverOutbound"
    address_prefixes  = ["10.0.5.0/24"]
    service_endpoints = []
    delegation = {
      name = "Microsoft.Network.dnsResolvers"
      service_delegation = {
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        name    = "Microsoft.Network/dnsResolvers"
      }
    }
    user_defined_routes = []
  } : null

  bastion_host_subnet = local.enable_bastion == true ? {
    name                = "AzureBastionSubnet"
    address_prefixes    = ["10.0.6.0/24"]
    service_endpoints   = []
    delegation          = null
    user_defined_routes = []
  } : null

  subnets = [for subnet in [local.firewall_subnet, local.route_server_subnet, local.vpn_subnet, local.bastion_host_subnet, local.dns_resolver_inbound_subnet, local.dns_resolver_outbound_subnet] : subnet if subnet != null]
}


module "hub" {
  source              = "../../modules/network/vnet"
  resource_group_name = azurerm_resource_group.hub.name
  az_region           = local.az_region
  resource_postfix    = "${local.resource_postfix}-hub"

  vnet_config = {
    address_space = "10.0.0.0/16"
    subnets       = local.subnets
    dns_zones     = []
  }
  enable_flow_log = true
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

  dns_proxy = {
    enabled     = local.enable_dns_resolver
    dns_servers = local.enable_dns_resolver == true ? module.dns_resolver.0.inbound_endpoint_ips : null
  }
}


module "bastion" {
  source = "../../modules/network/bastion"
  count  = local.enable_bastion == true ? 1 : 0

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.hub.name
  resource_postfix    = local.resource_postfix

  subnet_id = module.hub.subnets_by_name["AzureBastionSubnet"].id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  depends_on = [azurerm_log_analytics_workspace.law]
}

module "dns_resolver" {
  source = "../../modules/network/dns_resolver"
  count  = local.enable_dns_resolver == true ? 1 : 0

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.hub.name
  resource_postfix    = local.resource_postfix

  outbound_subnet_id = module.hub.subnets_by_name["DNSResolverOutbound"].id
  inbound_subnet_id  = module.hub.subnets_by_name["DNSResolverInbound"].id
  vnet_id            = module.hub.id

  forwarding_rules = [{
    dns_servers = [{
      ip_address = module.onprem.0.dc_ip
    }]
    domain_name = "."
    rule_name   = "onprem_dns_zone"
  }]
}

module "dns_forwarding_rule_links" {
  source = "../../modules/network/dns_resolver/modules/forwarding_links"
  count  = local.enable_dns_resolver == true ? 1 : 0

  dns_forwarding_ruleset_id   = module.dns_resolver.0.dns_forwarding_ruleset_id
  dns_forwarding_ruleset_name = module.dns_resolver.0.dns_forwarding_ruleset_name
  linked_vnets                = [module.spoke_west.vnet, module.spoke_east.vnet, module.hub.vnet]
}

module "route_server" {
  source = "../../modules/network/route_server"
  count  = local.enable_route_server == true ? 1 : 0

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.hub.name
  resource_postfix    = local.resource_postfix

  subnet_id = module.hub.subnets_by_name["RouteServerSubnet"].id
}

module "vpn" {
  source = "../../modules/network/vpn_gateway"
  count  = local.enable_vpn == true ? 1 : 0

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.hub.name
  resource_postfix    = local.resource_postfix

  subnet_id = module.hub.subnets_by_name["GatewaySubnet"].id

  vpn_configuration = {
    active_active = false
    enable_bgp    = local.enable_bgp
    sku           = "VpnGw1"
    vpn_type      = "RouteBased"
    asn_number    = 65514
  }
  vpn_client_address_space = ["10.4.0.0/24"]

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

# module "er" {
#   source = "../../modules/network/vpn_gateway"
#   count = local.enable_er == true ? 1 : 0
# }

locals {
  default_firewall_route = local.enable_firewall ? {
    address_prefix         = "0.0.0.0/0"
    next_hop_in_ip_address = module.firewall.0.internal_ip
    name                   = "default-all-to-firewall"
    next_hop_type          = "VirtualAppliance"
  } : null

  spoke_routes = [for udr in [local.default_firewall_route] : udr if udr != null]
}

module "spoke_east" {
  source              = "../../modules/network/vnet"
  resource_group_name = azurerm_resource_group.east.name
  az_region           = local.az_region
  resource_postfix    = "${local.resource_postfix}-spoke_east"

  vnet_config = {
    address_space = "10.1.0.0/24"
    subnets = [{
      address_prefixes    = ["10.1.0.0/28"]
      name                = "default"
      delegation          = null
      enable_nsg          = true
      service_endpoints   = local.enable_service_endpoint == true ? ["Microsoft.Storage"] : []
      user_defined_routes = local.spoke_routes
      network_rules = [
        {
          name                         = "deny_all_outbound"
          protocol                     = "Tcp"
          access                       = "Allow"
          destination_port_ranges      = ["0-65535"]
          source_address_prefixes      = ["0.0.0.0/0"]
          destination_address_prefixes = ["0.0.0.0/0"]
          direction                    = "Outbound"
        }
      ]
    }]
    dns_zones = []
  }
  peering = [{
    local = {
      allow_forwarded_traffic      = true
      allow_gateway_transit        = false
      allow_virtual_network_access = true
      use_remote_gateways          = local.enable_vpn
    }
    remote = {
      id                           = module.hub.id
      name                         = module.hub.name
      allow_forwarded_traffic      = true
      allow_gateway_transit        = local.enable_vpn
      allow_virtual_network_access = true
      use_remote_gateways          = false
      resource_group_name          = azurerm_resource_group.hub.name
    }
  }]
  # we do not need to set dns server ip to private resolver inbound endpoint
  custom_dns_servers = local.enable_dns_resolver == true && local.enable_firewall == true ? [module.firewall.0.internal_ip] : []
  enable_flow_log    = true

  depends_on = [module.vpn, module.firewall]
}


module "vm_east" {
  source = "../../modules/compute/vm"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.east.name
  resource_postfix    = local.resource_postfix

  vm_name = "vmeast"

  # @
  admin_username = ""
  admin_password = ""

  vm_sku = "Standard_B2s"

  subnet_id = module.spoke_east.subnets_by_name["default"].id

  data_disks = []

  enable_public_ip = false

  active_directory = null

  enable_diagnostics = true
}


module "spoke_west" {
  source              = "../../modules/network/vnet"
  resource_group_name = azurerm_resource_group.west.name
  az_region           = local.az_region
  resource_postfix    = "${local.resource_postfix}-spoke_west"

  vnet_config = {
    address_space = "10.1.1.0/24"
    subnets = [{
      address_prefixes    = ["10.1.1.0/28"]
      name                = "default"
      delegation          = null
      enable_nsg          = true
      service_endpoints   = []
      user_defined_routes = local.spoke_routes
    }]
    dns_zones = []
  }
  peering = [{
    local = {
      allow_forwarded_traffic      = true
      allow_gateway_transit        = false
      allow_virtual_network_access = true
      use_remote_gateways          = local.enable_vpn
    }
    remote = {
      id                           = module.hub.id
      name                         = module.hub.name
      allow_forwarded_traffic      = true
      allow_gateway_transit        = local.enable_vpn
      allow_virtual_network_access = true
      use_remote_gateways          = false
      resource_group_name          = azurerm_resource_group.hub.name
    }
  }]
  # we do not need to set dns server ip to private resolver inbound endpoint
  custom_dns_servers = local.enable_dns_resolver == true && local.enable_firewall == true ? [module.firewall.0.internal_ip] : []
  enable_flow_log    = true

  depends_on = [module.vpn, module.firewall]
}


module "vm_west" {
  source = "../../modules/compute/vm"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.west.name
  resource_postfix    = local.resource_postfix

  vm_name = "vmwest"

  admin_username = ""
  admin_password = ""

  vm_sku = "Standard_B2s"

  subnet_id = module.spoke_west.subnets_by_name["default"].id

  data_disks = []

  enable_public_ip     = false
  os_disk_storage_type = "StandardSSD_LRS"
  active_directory     = null

  enable_diagnostics = true
}


module "dns" {
  source = "../../modules/network/dns"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.dns.name
  resource_postfix    = local.resource_postfix

  dns_zones = [{
    name                     = ""
    enable_auto_registration = false
    },
    {
      name                     = "privatelink.blob.core.windows.net"
      enable_auto_registration = false
  }]
  vnet = module.hub.vnet
}


resource "azurerm_route_table" "vpn_to_firewall" {
  count = local.enable_firewall == true ? 1 : 0

  name                = "rt_vpn"
  location            = local.az_region
  resource_group_name = azurerm_resource_group.hub.name

  route = [
    {
      name                   = "for_spokewest_to_firewall"
      next_hop_type          = "VirtualAppliance"
      address_prefix         = "10.1.1.0/24"
      next_hop_in_ip_address = module.firewall.0.internal_ip
    },
    {
      name                   = "for_spokeeast_to_firewall"
      next_hop_type          = "VirtualAppliance"
      address_prefix         = "10.1.0.0/24"
      next_hop_in_ip_address = module.firewall.0.internal_ip
    }
  ]

  disable_bgp_route_propagation = false
}

resource "azurerm_subnet_route_table_association" "vpn_to_firewall" {
  count = local.enable_firewall == true ? 1 : 0

  route_table_id = azurerm_route_table.vpn_to_firewall.0.id
  subnet_id      = module.hub.subnets_by_name["GatewaySubnet"].id
}


module "onprem" {
  source = "../onprem"

  count = local.enable_vpn == true ? 1 : 0

  address_space          = "172.16.0.0/24"
  gateway_subnet_newbits = 3
  default_subnet_newbits = 4

  resource_prefix = "standard"
  enable_bgp      = local.enable_bgp

  active_directory = {
    domain_name  = local.active_directory.domain_name
    netbios_name = local.active_directory.netbios_name
  }
}

module "vpn_connection" {
  source = "../../modules/network/vpn_gateway_connection"

  count = local.enable_vpn == true ? 1 : 0

  az_region        = local.az_region
  resource_postfix = "gateway_connection"

  local_resource_group_name  = azurerm_resource_group.hub.name
  remote_resource_group_name = module.onprem.0.rg_name

  connection = {
    azure_gateway_id  = module.vpn.0.id
    onprem_gateway_id = module.onprem.0.vpn_id
    enable_bgp        = local.enable_bgp
    shared_key        = ""
    name              = "connection-onprem-hub_spoke"
  }
}
locals {
  subnet_ids = local.enable_service_endpoint == true ? [module.spoke_east.subnets_by_name["default"].id] : null
}

locals {
  network_rules = local.enable_service_endpoint == true ? {
    default_action = "Deny"
    bypass         = []
    ip_rules       = []
    subnet_ids     = local.subnet_ids
    } : {
    default_action = "Allow"
    bypass         = []
    ip_rules       = []
    subnet_ids     = []
  }
}

resource "azurerm_resource_group" "stga" {
  name     = "rg-${local.resource_postfix}-storage"
  location = local.az_region
}

module "storage_account" {
  source = "../../modules/paas/storage_account"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.stga.name
  resource_postfix    = local.resource_postfix

  subnet_id = module.spoke_east.subnets_by_name["default"].id

  enable_private_endpoint      = local.enable_private_endpoint
  enable_service_endpoint      = local.enable_service_endpoint
  enable_public_network_access = local.enable_public_network_access

  private_dns_zone_ids = local.enable_private_endpoint == true ? module.dns.0.zone_ids : []

  containers_list = ["container01", "container02"]

  network_rules = local.enable_private_endpoint == false ? local.network_rules : null

  depends_on = [module.dns]
}


resource "azurerm_resource_group" "monitoring" {
  name     = "rg-${local.resource_postfix}-monitoring"
  location = local.az_region
}


resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-central-monitoring-${local.resource_postfix}"
  location            = local.az_region
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


locals {
  east_endpoint = {
    name        = "east"
    resource_id = module.vm_east.vm_id
  }
  west_endpoint = {
    name        = "west"
    resource_id = module.vm_west.vm_id
  }
  dc_endpoint = local.enable_vpn == true ? {
    name       = "dc1"
    ip_address = module.onprem.0.dc_ip
  } : null
  endpoints_to_monitor = [for endpoint in [local.east_endpoint, local.west_endpoint, local.dc_endpoint] : endpoint if endpoint != null]

  east_west_testgroup = {
    name                     = "east_to_west_tcp"
    destinations             = ["west"]
    sources                  = ["east"]
    test_configuration_names = ["tcp_config"]
  }
  west_east_testgroup = {
    name                     = "west_to_east_tcp"
    destinations             = ["east"]
    sources                  = ["west"]
    test_configuration_names = ["tcp_config"]
  }
  east_dc_testgroup = local.enable_vpn == true ? {
    name                     = "east_to_onprem_dc1"
    destinations             = ["dc1"]
    sources                  = ["east"]
    test_configuration_names = ["tcp_config"]
  } : null
  test_groups = [for endpoint in [local.east_west_testgroup, local.west_east_testgroup, local.east_dc_testgroup] : endpoint if endpoint != null]

}

module "connection_monitoring" {
  source = "../../modules/monitoring/connection_monitor"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.monitoring.name
  resource_postfix    = local.resource_postfix

  endpoints = local.endpoints_to_monitor

  test_configurations = [{
    name                      = "tcp_config"
    protocol                  = "Tcp"
    test_frequency_in_seconds = 30
  }]

  test_groups = local.test_groups
}