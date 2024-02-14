resource "azurerm_public_ip" "default" {
  name                = "pip-agw-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region
  allocation_method   = "Static"

  sku = "Standard"
}


locals {
  priv_frontend_ip_configuration_name = "agw-${var.resource_postfix}-fepriv"
  backend_address_pool_name           = "agw-${var.resource_postfix}-beap"
  frontend_port_name                  = "agw-${var.resource_postfix}-feport"
  frontend_ip_configuration_name      = "agw-${var.resource_postfix}-feip"
  http_setting_name                   = "agw-${var.resource_postfix}-be-htst"
  listener_name                       = "agw-${var.resource_postfix}-httplstn"
  request_routing_rule_name           = "agw-${var.resource_postfix}-rqrt"
  redirect_configuration_name         = "agw-${var.resource_postfix}-rdrcfg"
  probe_name                          = "agw-${var.resource_postfix}-probe"
}


resource "azurerm_application_gateway" "default" {
  name                = "agw-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  probe {
    interval                                  = 30
    name                                      = local.probe_name
    path                                      = "/"
    port                                      = 80
    protocol                                  = "Http"
    timeout                                   = 10
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.default.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                                = local.http_setting_name
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    probe_name                          = local.probe_name
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.default.id
}

resource "azurerm_web_application_firewall_policy" "default" {
  name                = "wafpolicy-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  custom_rules {
    name      = "Rule1"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
    }

    action = "Block"
  }

  custom_rules {
    name      = "Rule2"
    priority  = 2
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24"]
    }

    match_conditions {
      match_variables {
        variable_name = "RequestHeaders"
        selector      = "UserAgent"
      }

      operator           = "Contains"
      negation_condition = false
      match_values       = ["Windows"]
    }

    action = "Block"
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    exclusion {
      match_variable          = "RequestHeaderNames"
      selector                = "x-company-secret-header"
      selector_match_operator = "Equals"
    }
    exclusion {
      match_variable          = "RequestCookieNames"
      selector                = "too-tasty"
      selector_match_operator = "EndsWith"
    }

    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rule {
          id      = "920300"
          enabled = true
          action  = "Log"
        }

        rule {
          id      = "920440"
          enabled = true
          action  = "Block"
        }
      }
    }
  }
}


resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "default" {
  for_each = { for idx, vm in var.vm_backend_configs : idx => vm }

  network_interface_id    = each.value.nic_id
  ip_configuration_name   = each.value.nic_ip_configuration_name
  backend_address_pool_id = tolist(azurerm_application_gateway.default.backend_address_pool).0.id
}