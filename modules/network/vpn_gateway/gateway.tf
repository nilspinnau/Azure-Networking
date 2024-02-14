resource "azurerm_public_ip" "default" {
  name                = "pip-vpn-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_virtual_network_gateway" "default" {
  name                = "vpn-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = var.vpn_configuration.vpn_type

  active_active = var.vpn_configuration.active_active
  enable_bgp    = var.vpn_configuration.enable_bgp
  sku           = var.vpn_configuration.sku

  ip_configuration {
    name                          = "default-config"
    public_ip_address_id          = azurerm_public_ip.default.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_id
  }

  dynamic "bgp_settings" {
    for_each = var.vpn_configuration.enable_bgp == true ? [1] : []
    content {
      asn         = var.vpn_configuration.asn_number
      peer_weight = 10
    }
  }

  dynamic "vpn_client_configuration" {
    for_each = length(var.vpn_client_address_space) > 0 ? [1] : []
    content {
      address_space        = var.vpn_client_address_space
      vpn_auth_types       = ["Certificate", "AAD"]
      vpn_client_protocols = ["IkeV2", "OpenVPN"]

      root_certificate {
        name             = "self-issued"
        public_cert_data = <<EOF
        EOF
      }

      aad_audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
      aad_issuer   = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/"
      aad_tenant   = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}"
    }
  }
}

data "azurerm_client_config" "current" {
}

