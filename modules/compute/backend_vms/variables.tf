variable "az_region" {
  type        = string
  description = "Determines in which Azure region the resources should be deployed in."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the VMs."
}

variable "vm_name" {
  type = string
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "vm_sku" {
  type        = string
  description = "Azure VM SKU, determines the Azure vCPU, vRAM etc. for the VMs. More information see: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes"
}

variable "os_disk_size" {
  type        = number
  default     = 128
  description = "The OS disk size of the VMs."
}

variable "resource_postfix" {
  type        = string
  description = "Postfix for all resources which will be deployed."
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet in which to deploy the VMs."
}

variable "admin_password" {
  sensitive   = true
  type        = string
  description = "Password for the VM admin account."
}

variable "admin_username" {
  type        = string
  description = "Username for the VM admin account."
}

variable "os_disk_storage_type" {
  type    = string
  default = "StandardSSD_LRS"
  validation {
    condition = contains([
      "Standard_LRS", "StandardSSD_ZRS", "Premium_LRS", "Premium_ZRS", "StandardSSD_LRS"
    ], var.os_disk_storage_type)
    error_message = "Disk type is not supported for os disk. Supported types are: ['Standard_LRS', 'StandardSSD_ZRS', 'Premium_LRS', 'Premium_ZRS', 'StandardSSD_LRS']"
  }
}


variable "data_disks" {
  type = list(object({
    lun           = number
    type          = optional(string, "StandardSSD_LRS")
    create_option = optional(string, "Empty")
    disk_size_gb  = number
    caching       = optional(string, "ReadOnly")
  }))
  default = []
}

variable "enable_public_ip" {
  type     = bool
  default  = false
  nullable = false
}
