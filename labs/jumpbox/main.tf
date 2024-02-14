

locals {
  az_region        = "eastus"
  resource_postfix = "eastus-test-jumpbox"
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
    address_space = "10.99.0.0/16"
    subnets = [
      {
        name                = "jumpbox"
        address_prefixes    = ["10.99.0.0/24"]
        service_endpoints   = []
        delegation          = null
        user_defined_routes = []
      },
      {
        name                = "vmsubnet"
        address_prefixes    = ["10.99.1.0/24"]
        service_endpoints   = []
        delegation          = null
        user_defined_routes = []
        enable_nsg          = true
        network_rules = [
          {
            name                         = "allow_jumpbox_inbound"
            protocol                     = "Tcp"
            access                       = "Allow"
            destination_port_ranges      = [3389]
            source_address_prefixes      = ["10.99.0.0/24"]
            destination_address_prefixes = null
            direction                    = "Inbound"
          }
        ]
      }
    ]
    dns_zones = []
  }
}


module "jumpbox" {
  source = "../../modules/compute/vm"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  vm_name = "jumpbox"

  admin_username = ""
  admin_password = ""

  vm_sku = "Standard_B2s"

  subnet_id = module.hub.subnets_by_name["jumpbox"].id

  data_disks = []

  enable_public_ip = true

  active_directory = null

  enable_asg = true
}


module "vm" {
  source = "../../modules/compute/vm"

  az_region           = local.az_region
  resource_group_name = azurerm_resource_group.rg.name
  resource_postfix    = local.resource_postfix

  vm_name = "vmtoreach"

  admin_username = ""
  admin_password = ""

  vm_sku = "Standard_B2s"

  subnet_id = module.hub.subnets_by_name["vmsubnet"].id

  data_disks = []

  enable_public_ip = false

  active_directory = null

  enable_asg = true
}