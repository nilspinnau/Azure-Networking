
locals {
  az_region        = "eastus"
  resource_postfix = "eastus-test-private_access"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.resource_postfix}"
  location = local.az_region
}

module "hub" {
  source              = "../../modules/network/vnet"
  resource_group_name = azurerm_resource_group.rg.name
  az_region           = local.az_region
  resource_postfix    = "${local.az_region}-test-hub"

  vnet_config = {
    address_space = "10.10.0.0/16"
    subnets = [
      {
        name                = "default"
        address_prefixes    = ["10.10.1.0/24"]
        service_endpoints   = local.enable_service_endpoint == true ? ["Microsoft.Storage"] : []
        delegation          = null
        user_defined_routes = []
      }
    ]
    dns_zones = []
  }
}

# module "bastion" {
#   source = "../../modules/network/bastion"

#   az_region           = local.az_region
#   resource_group_name = azurerm_resource_group.rg.name
#   resource_postfix    = local.resource_postfix

#   subnet_id = module.hub.subnets_by_name["AzureBastionSubnet"].id

#   sku = "Basic"
# }

module "vm" {
  source = "../../modules/compute/vm"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  vm_name = "vmprivaccess"

  admin_username = ""
  admin_password = ""

  vm_sku = "Standard_B2s"

  subnet_id = module.hub.subnets_by_name["default"].id

  data_disks = []

  enable_public_ip = true

  active_directory = null

  extensions = false

  enable_asg = false
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

locals {
  subnet_ids = local.enable_service_endpoint == true ? [module.hub.subnets_by_name["default"].id] : null
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


module "storage_account" {
  source = "../../modules/paas/storage_account"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  subnet_id = module.hub.subnets_by_name["default"].id

  enable_private_endpoint      = local.enable_private_endpoint
  enable_service_endpoint      = local.enable_service_endpoint
  enable_public_network_access = local.enable_public_network_access

  private_dns_zone_ids = local.enable_private_endpoint == true ? module.dns.0.zone_ids : []

  containers_list = ["container01", "container02"]

  network_rules = local.enable_private_endpoint == false ? local.network_rules : null

  depends_on = [module.dns]
}


module "dns" {
  source = "../../modules/network/dns"
  count  = local.enable_private_endpoint == true ? 1 : 0

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  dns_zones = [{
    name                     = "privatelink.blob.core.windows.net"
    enable_auto_registration = false
  }]
  vnet = module.hub.vnet
}