
resource "random_string" "storage_account_name" {
  length  = 15
  upper   = false
  special = false
}

resource "azurerm_storage_account" "default" {
  name                = "sta${random_string.storage_account_name.result}"
  resource_group_name = var.resource_group_name

  location                 = var.az_region
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  access_tier = "Hot"

  cross_tenant_replication_enabled  = false
  infrastructure_encryption_enabled = true

  sftp_enabled = false

  # we have soft delete enabled thus this cannot be enabled
  is_hns_enabled = false
  nfsv3_enabled  = false

  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled   = var.enable_public_network_access
  allow_nested_items_to_be_public = var.enable_public_network_access

  network_rules {
    default_action             = try(var.network_rules.default_action, "Deny")
    bypass                     = distinct(try(var.network_rules.bypass, []))
    ip_rules                   = try(var.network_rules.ip_rules, [])
    virtual_network_subnet_ids = try(var.network_rules.subnet_ids, [])
  }

  depends_on = [random_string.storage_account_name]
}

resource "azapi_resource" "containers" {
  for_each = toset(var.containers_list)

  name      = lower(each.value)
  parent_id = "${azurerm_storage_account.default.id}/blobServices/default"
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01"
  body = jsonencode({
    properties = {
      publicAccess = "None"
    }
  })

  depends_on = [azurerm_storage_account.default]
}


resource "azurerm_private_endpoint" "pe_storage_account" {
  count = var.enable_private_endpoint == true ? 1 : 0

  location            = var.az_region
  name                = "pep-${azurerm_storage_account.default.name}-${var.resource_postfix}"
  resource_group_name = var.resource_group_name

  subnet_id = var.subnet_id

  private_service_connection {
    name                           = "con-${azurerm_storage_account.default.name}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.default.id
    subresource_names = [
      "blob"
    ]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_ids != [] ? [1] : []
    content {
      name                 = "dns-zone-group-0"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }
}