
resource "random_string" "storage_account_name" {
  count   = var.enable_flow_log == true ? 1 : 0
  length  = 15
  upper   = false
  special = false
}


resource "azurerm_log_analytics_workspace" "default" {
  count = var.enable_log_analytics == true && var.enable_flow_log == true ? 1 : 0

  name                = "law-nsg-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  sku               = "PerGB2018"
  retention_in_days = 30
}


# storage account required for the 
resource "azurerm_storage_account" "flow_log_stga" {
  count = var.enable_flow_log == true ? 1 : 0

  name                = "flowlogs${random_string.storage_account_name.0.result}"
  location            = var.az_region
  resource_group_name = var.resource_group_name

  # checkov:skip=CKV2_AZURE_1: We dont use customer managed key

  # checkov:skip=CKV_AZURE_33: We will not be using Queue service

  # checkov:skip=CKV2_AZURE_33: We do not use private endpoint for this
  # checkov:skip=CKV_AZURE_206: LRS replication is enough for Azure backup

  # checkov:skip=CKV2_AZURE_38: soft delete should be enabled since we only use this account for staging of azure backups


  # checkov:skip=CKV2_AZURE_40: We ignore this, so we do not have to set the Storage Contributor rights etc

  account_kind = "StorageV2"
  account_tier = "Standard"

  access_tier = "Hot"
  # TODO:
  # check if this should be GRS for site recovery and backups in geo redundant types
  # if the whole region goes down the storage account can be transferred to the secondary region and thus no new storage account is required, only fallover
  account_replication_type = "LRS"

  cross_tenant_replication_enabled = false
  allow_nested_items_to_be_public  = false

  shared_access_key_enabled = true

  enable_https_traffic_only         = true
  infrastructure_encryption_enabled = true

  min_tls_version = "TLS1_2"

  public_network_access_enabled = true
  # https://learn.microsoft.com/en-us/azure/network-watcher/network-watcher-nsg-flow-logging-cli
  network_rules {
    bypass                     = ["AzureServices", "Metrics", "Logging"]
    default_action             = "Deny"
    virtual_network_subnet_ids = [for subnet in azurerm_subnet.subnets : subnet.id]
    ip_rules                   = []
  }
}

resource "azurerm_network_watcher_flow_log" "flow_logs" {
  count = var.enable_flow_log == true ? 1 : 0

  network_watcher_name = "NetworkWatcher_${var.az_region}"
  resource_group_name  = "NetworkWatcherRG"
  location             = var.az_region
  name                 = "flowlogs-${azurerm_network_security_group.nsg.name}"

  network_security_group_id = azurerm_network_security_group.nsg.id
  storage_account_id        = azurerm_storage_account.flow_log_stga.0.id
  enabled                   = true

  dynamic "traffic_analytics" {
    for_each = var.enable_log_analytics == true ? [1] : []
    content {
      enabled               = true
      workspace_id          = azurerm_log_analytics_workspace.default.0.workspace_id
      workspace_region      = azurerm_log_analytics_workspace.default.0.location
      workspace_resource_id = azurerm_log_analytics_workspace.default.0.id
      interval_in_minutes   = 10
    }
  }

  version = 2

  retention_policy {
    enabled = true
    days    = 7
  }
}