data "azurerm_client_config" "current" {}

resource "azurerm_vpn_server_configuration" "test" {
  name                = "p2s-default-config"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  vpn_protocols            = ["IkeV2", "OpenVPN"]
  vpn_authentication_types = ["Certificate", "AAD"]

  client_root_certificate {
    name             = "self-issued"
    public_cert_data = <<EOF
    EOF
  }

  azure_active_directory_authentication {
    audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
    issuer   = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/"
    tenant   = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}"
  }

  dynamic "ipsec_policy" {
    for_each = var.p2s_ipsec_policy != null ? [1] : []
    content {
      dh_group               = var.p2s_ipsec_policy.dh_group
      ike_encryption         = var.p2s_ipsec_policy.ike_encryption_algorithm
      ike_integrity          = var.p2s_ipsec_policy.ike_integrity_algorithm
      ipsec_encryption       = var.p2s_ipsec_policy.encryption_algorithm
      ipsec_integrity        = var.p2s_ipsec_policy.integrity_algorithm
      pfs_group              = var.p2s_ipsec_policy.pfs_group
      sa_data_size_kilobytes = var.p2s_ipsec_policy.sa_data_size_kb
      sa_lifetime_seconds    = var.p2s_ipsec_policy.sa_lifetime_sec
    }
  }
}