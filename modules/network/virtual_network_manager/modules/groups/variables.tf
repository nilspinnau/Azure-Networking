

variable "network_group" {
  type = object({
    name = string
    members = list(object({
      name = string
      id   = string
    }))
  })
}

variable "network_manager_id" {
  type = string
}