

locals {
  az_region        = "eastus"
  resource_postfix = "eastus-test-lb_sols"
}


locals {
  enable_traffic_manager = false
  enable_load_balancer   = true
  enable_app_gateway     = false
  enable_front_door      = false
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_postfix}"
  location = local.az_region
}

locals {
  nsg_rules_tm = [
    # allows the health probe to successfully check the endpoint health
    {
      name                    = "allow_traffic_manager"
      protocol                = "Tcp"
      access                  = "Allow"
      destination_port_ranges = [80]
      source_address_prefix   = "AzureTrafficManager"
      direction               = "Inbound"
    },
    # traffic manager we connect to endpoint, thus client ip has to have access on the endpoints
    {
      name                    = "allow_public_access_to_endpoint"
      protocol                = "Tcp"
      access                  = "Allow"
      destination_port_ranges = [80]
      source_address_prefix   = "<my_client_ip>"
      direction               = "Inbound"
    }
  ]
  nsg_rules_others = [
    # for app gateway
    {
      name                    = "allow_agw_inbound"
      protocol                = "*"
      access                  = "Allow"
      destination_port_ranges = ["65200-65535"]
      source_address_prefix   = "GatewayManager"
      direction               = "Inbound"
    }
  ]
}

module "hub" {
  source              = "../../modules/network/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  az_region           = local.az_region
  resource_postfix    = "${local.az_region}-test-hub"

  vnet_config = {
    address_space = "10.20.0.0/20"
    subnets = [
      {
        name                = "appgw_subnet"
        address_prefixes    = ["10.20.0.0/24"]
        service_endpoints   = []
        delegation          = null
        user_defined_routes = []
        network_rules       = local.enable_traffic_manager == true ? local.nsg_rules_tm : local.nsg_rules_others
        enable_nsg          = false
      },
      {
        name                = "vmsubnet"
        address_prefixes    = ["10.20.1.0/28"]
        service_endpoints   = []
        delegation          = null
        user_defined_routes = []
        network_rules       = local.enable_traffic_manager == true ? local.nsg_rules_tm : local.nsg_rules_others
        enable_nsg          = true
      }
    ]
    dns_zones = []
  }
}

module "loadbalancer" {
  source = "../../modules/network/loadbalancer"
  count  = local.enable_load_balancer == true ? 1 : 0

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  loadbalancing_rules = [{
    name          = "Http"
    protocol      = "Tcp"
    tcp_reset     = true
    backend_port  = 80
    frontend_port = 80
  }]

  health_probe = {
    path     = "/"
    port     = 80
    protocol = "Tcp"
  }

  subnet_id = module.hub.subnets_by_name["vmsubnet"].id

  public_endpoint = true

  vm_backend_configs = module.backend_vms.vm_backend_configs
}

module "app_gateway" {
  source = "../../modules/network/app_gateway"
  count  = local.enable_app_gateway == true ? 1 : 0

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  subnet_id          = module.hub.subnets_by_name["appgw_subnet"].id
  vm_backend_configs = module.backend_vms.vm_backend_configs
}

locals {
  backends_length = length(module.backend_vms.vm_backend_configs)
  tm_backends = [for idx, backend in module.backend_vms.vm_backend_configs : {
    name      = backend.vm_name
    target_id = backend.public_ip
    priority  = idx + 1
  }]
}

module "traffic_manager" {
  source = "../../modules/network/traffic_manager"
  count  = local.enable_traffic_manager == true ? 1 : 0

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  backends = local.tm_backends

  probe = {
    path     = "/"
    protocol = "HTTP"
    port     = 80
  }
}


module "backend_vms" {
  source = "../../modules/compute/backend_vms"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  vm_name = "backendvm"

  admin_username = ""
  admin_password = ""

  vm_sku = "Standard_B2s"

  subnet_id = module.hub.subnets_by_name["vmsubnet"].id

  enable_public_ip = local.enable_traffic_manager
  instance_count   = 2

  data_disks = []
}