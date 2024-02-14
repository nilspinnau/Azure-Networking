
resource "azurerm_managed_disk" "vm_disks" {
  # we create x disks for each vm we create
  for_each = { for data_disk in var.data_disks : data_disk.lun => data_disk }

  name                = "disk-${var.resource_postfix}-${each.value.lun}-${each.value.letter}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  storage_account_type = each.value.type
  create_option        = each.value.create_option
  disk_size_gb         = each.value.disk_size_gb

  zone = null
}


resource "azurerm_virtual_machine_data_disk_attachment" "vm_disk_attachment" {
  for_each = { for data_disk in var.data_disks : data_disk.lun => data_disk }

  managed_disk_id    = azurerm_managed_disk.vm_disks[each.value.lun].id
  virtual_machine_id = azurerm_windows_virtual_machine.win_vm.id

  lun     = each.value.lun
  caching = each.value.caching

  depends_on = [
    azurerm_managed_disk.vm_disks
  ]
}
