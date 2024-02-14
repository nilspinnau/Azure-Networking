

resource "azurerm_public_ip" "default" {
  count = var.public_endpoint == true ? 1 : 0

  name                = "pip-lb-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  allocation_method = "Static"
  sku               = "Standard"
}


resource "azurerm_lb" "lb" {
  name                = "lb-${var.resource_postfix}"
  location            = var.az_region
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name = "internal"
    # TODO check the first possible private ip to assign
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
    subnet_id                     = var.public_endpoint == true ? null : var.subnet_id
    public_ip_address_id          = var.public_endpoint == true ? azurerm_public_ip.default.0.id : null
  }

  sku      = "Standard"
  sku_tier = "Regional"
}

resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {

  loadbalancer_id = azurerm_lb.lb.id
  name            = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "default" {
  for_each = { for idx, vm in var.vm_backend_configs : idx => vm }

  network_interface_id    = each.value.nic_id
  ip_configuration_name   = each.value.nic_ip_configuration_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_pool.id
}

resource "azurerm_lb_probe" "health_probe" {
  name = "healthprobe_${var.health_probe.protocol}_${var.health_probe.port}"

  port = var.health_probe.port
  # only allowed when protocol is Http or Https
  request_path        = var.health_probe.protocol != "Tcp" ? var.health_probe.path : null
  protocol            = var.health_probe.protocol
  interval_in_seconds = 10
  loadbalancer_id     = one(azurerm_lb.lb[*].id)
}


# we can do only so much with terraform, if there is nothing given then the app owner does it themselves, its not magic
resource "azurerm_lb_rule" "inbound" {
  for_each = { for rule in var.loadbalancing_rules : rule.name => rule }

  name = each.value.name

  backend_port  = each.value.backend_port
  frontend_port = each.value.frontend_port
  protocol      = each.value.protocol

  enable_floating_ip = each.value.floating_ip
  enable_tcp_reset   = each.value.tcp_reset

  load_distribution = each.value.load_distribution

  idle_timeout_in_minutes = 4

  probe_id                       = azurerm_lb_probe.health_probe.id
  loadbalancer_id                = azurerm_lb.lb.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration.0.name

  depends_on = [azurerm_lb_probe.health_probe]
}
