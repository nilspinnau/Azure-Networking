
resource "azurerm_virtual_network_gateway_connection" "azure_to_onprem" {

  name                = "connection-to-onprem"
  resource_group_name = var.local_resource_group_name
  location            = var.az_region

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = var.connection.azure_gateway_id
  peer_virtual_network_gateway_id = var.connection.onprem_gateway_id

  shared_key = var.connection.shared_key

  enable_bgp = var.connection.enable_bgp
}

resource "azurerm_virtual_network_gateway_connection" "onprem_to_azure" {

  name                = "connection-to-azure"
  resource_group_name = var.remote_resource_group_name
  location            = var.az_region

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = var.connection.onprem_gateway_id
  peer_virtual_network_gateway_id = var.connection.azure_gateway_id

  enable_bgp = var.connection.enable_bgp

  shared_key = var.connection.shared_key
}