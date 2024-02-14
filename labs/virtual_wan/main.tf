


locals {
  az_region        = "eastus"
  resource_postfix = "eastus-test-vwan"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_postfix}"
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

module "onprem" {
  source                 = "../onprem"
  address_space          = "172.16.0.0/24"
  gateway_subnet_newbits = 3
  default_subnet_newbits = 4

  resource_prefix      = "vwan"
  enable_bgp           = false
  remote_address_space = "10.0.0.0/8"
}

locals {
  shared_key = ""
}

module "virtual_wan" {
  source = "../../modules/network/virtual_wan"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  wan_sku = "Standard"
  hubs = [{
    name                   = "hub01"
    address_prefix         = "10.0.0.0/20"
    az_region              = local.az_region
    hub_routing_preference = "VpnGateway"
    enable_vpn             = true
    enable_er              = false
    enable_firewall        = true
    remote_sites = [{
      name          = "onprem"
      address_cidrs = ["172.16.0.0/24"]
      vpn_links = [{
        provider_name = "test"
        name          = "onprem"
        enable_bgp    = false
        ip_address    = module.onprem.vpn_ip
        speed_in_mbps = 100
        shared_key    = local.shared_key
      }]
    }]
    rule_collection_groups = jsondecode(file("./firewall_rules.json"))
  }]
  spokes = local.spokes

  route_tables = [
    {
      name     = "redRT"
      hub_name = "hub01"
      routes = [
        {
          name              = "toFirewall"
          next_hop_type     = "ResourceId"
          destinations      = ["0.0.0.0/0"]
          destinations_type = "CIDR"
          next_hop          = "firewall"
        }
      ]
    },
    {
      name     = "blueRT"
      hub_name = "hub01"
      routes = [
        {
          name              = "toFirewall"
          next_hop_type     = "ResourceId"
          destinations      = ["0.0.0.0/0"]
          destinations_type = "CIDR"
          next_hop          = "firewall"
        }
      ]
    }
  ]
}


locals {
  spokes = [
    {
      name                = "red01"
      address_space       = ["10.1.0.0/24"]
      az_region           = local.az_region
      hub_name            = "hub01"
      route_table_name    = "redRT"
      propagate_itself    = false
      propagated_labels   = ["none"]
      resource_group_name = azurerm_resource_group.red.name
      subnets = [{
        name           = "default"
        address_prefix = "10.1.0.0/29"
        id             = null
        security_group = null
      }]
    },
    {
      name                = "red02"
      address_space       = ["10.1.1.0/24"]
      az_region           = local.az_region
      hub_name            = "hub01"
      route_table_name    = "redRT"
      propagate_itself    = false
      propagated_labels   = ["none"]
      resource_group_name = azurerm_resource_group.red.name
      subnets = [{
        name           = "default"
        address_prefix = "10.1.1.0/29"
        id             = null
        security_group = null
      }]
    },
    {
      name                = "blue01"
      address_space       = ["10.1.2.0/24"]
      az_region           = local.az_region
      hub_name            = "hub01"
      route_table_name    = "blueRT"
      propagate_itself    = true
      propagated_labels   = []
      resource_group_name = azurerm_resource_group.blue.name
      subnets = [{
        name           = "default"
        address_prefix = "10.1.2.0/29"
        id             = null
        security_group = null
      }]
    },
    {
      name                = "blue02"
      address_space       = ["10.1.3.0/24"]
      az_region           = local.az_region
      hub_name            = "hub01"
      route_table_name    = "blueRT"
      propagate_itself    = true
      propagated_labels   = []
      resource_group_name = azurerm_resource_group.blue.name
      subnets = [{
        name           = "default"
        address_prefix = "10.1.3.0/29"
        id             = null
        security_group = null
      }]
    }
  ]
}


module "vms" {
  source = "../../modules/compute/vm"

  for_each = { for idx, spoke in local.spokes : spoke.name => spoke }

  az_region           = local.az_region
  resource_postfix    = "${local.az_region}-${each.value.name}"
  resource_group_name = each.value.resource_group_name

  subnet_id = one(module.virtual_wan.spokes_by_id[each.key].subnet).id
  vm_sku    = "Standard_B2s"
  vm_name   = "vmvwan${each.value.name}"

  admin_username = ""
  admin_password = ""

  active_directory = null
  enable_asg       = false
  enable_public_ip = false
  extensions       = true
}

output "name" {
  value = module.virtual_wan.vpn_ips[0][1]
}

resource "azurerm_local_network_gateway" "azure_vwan" {

  name                = "connection-onprem-vwan"
  location            = local.az_region
  resource_group_name = module.onprem.rg_name
  address_space       = ["10.0.0.0/8"]

  gateway_address = module.virtual_wan.vpn_ips[0][1]
}

resource "azurerm_virtual_network_gateway_connection" "onprem_to_azure" {

  name                = "connection-to-azure"
  resource_group_name = module.onprem.rg_name
  location            = local.az_region

  type                       = "IPsec"
  virtual_network_gateway_id = module.onprem.vpn_id
  local_network_gateway_id   = azurerm_local_network_gateway.azure_vwan.id

  enable_bgp = false

  shared_key = local.shared_key
}