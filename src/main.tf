terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.21.1"
    }
  }
}

provider "azurerm" {
  subscription_id            = var.subscription_id
  tenant_id                  = var.tenant_id
  client_id                  = var.client_id
  client_secret              = var.client_secret
  skip_provider_registration = true
  features {}
}

data "azurerm_resource_group" "starter" {
  name = var.main_resource_group_name
}

resource "azurerm_log_analytics_workspace" "starter" {
  name                = "law-${var.naming_prefix}-${var.environment}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.starter.name
  sku                 = "PerGB2018"
  retention_in_days   = 730
}

resource "azurerm_application_insights" "starter" {
  name                = "ai-${var.naming_prefix}-${var.environment}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.starter.name
  workspace_id        = azurerm_log_analytics_workspace.starter.id
  application_type    = "web"
}

resource "azurerm_service_plan" "starter" {
  name                = "asp-${var.naming_prefix}-${var.environment}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.starter.name
  os_type             = "Linux"
  sku_name            = var.web_tier
}

resource "azurerm_service_plan" "starter-func" {
  name                = "asp-func-${var.naming_prefix}-${var.environment}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.starter.name
  os_type             = "Linux"
  sku_name            = var.api_tier
}

resource "azurerm_linux_web_app" "starter" {
  name                = "web-${var.naming_prefix}-${var.environment}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.starter.name
  service_plan_id     = azurerm_service_plan.starter.id
  https_only          = "true"

  app_settings = {
    API_URL                               = "https://${azurerm_linux_function_app.starter.default_hostname}"
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.starter.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.starter.connection_string
    APPINSIGHTS_ROLENAME                  = "web-${var.naming_prefix}-${var.environment}"
    WEBSITE_ENABLE_SYNC_UPDATE_SITE       = "true"
  }

  site_config {
    always_on        = var.web_always_on
    app_command_line = "NODE_ENV=production npm run start"
    ftps_state       = "Disabled"
    http2_enabled    = true
    application_stack {
      node_version = "16-lts"
    }
  }
}

resource "azurerm_linux_function_app" "starter" {
  name                       = "func-${var.naming_prefix}-${var.environment}"
  location                   = var.location
  resource_group_name        = data.azurerm_resource_group.starter.name
  service_plan_id            = azurerm_service_plan.starter-func.id
  storage_account_name       = azurerm_storage_account.starter.name
  storage_account_access_key = azurerm_storage_account.starter.primary_access_key
  https_only                 = true

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME              = "node"
    WEBSITE_ENABLE_SYNC_UPDATE_SITE       = "true"
    WEBSITE_NODE_DEFAULT_VERSION          = "~16"
    WEBSITE_RUN_FROM_PACKAGE              = "1"
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.starter.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.starter.connection_string
    APPINSIGHTS_ROLENAME                  = "func-${var.naming_prefix}-${var.environment}"
    COSMOSDB_ENDPOINT                     = azurerm_cosmosdb_account.starter.endpoint
    COSMOSDB_KEY                          = azurerm_cosmosdb_account.starter.primary_key
    COSMOSDB_STARTER_CONTAINER            = azurerm_cosmosdb_sql_container.starter.name
    DATABASE_NAME                         = var.database_name
  }

  site_config {
    application_insights_connection_string = azurerm_application_insights.starter.connection_string
    always_on                              = var.api_always_on
    http2_enabled                          = true
    application_stack {
      node_version = "16"
    }
    cors {
      allowed_origins = [
        "https://functions-staging.azure.com",
        "https://functions.azure.com",
        "https://functions-next.azure.com",
      ]
    }
  }
}

locals {
  default_frontend_endpoint_name = "${var.naming_prefix}-${var.environment}-fd-azurefd-net"
  default_frontend_endpoint      = "${var.naming_prefix}-${var.environment}-fd.azurefd.net"
}

resource "azurerm_frontdoor" "starter" {
  name                = "${var.naming_prefix}-${var.environment}-fd"
  friendly_name       = "${var.naming_prefix}-${var.environment}-fd"
  resource_group_name = data.azurerm_resource_group.starter.name

  # start: web
  frontend_endpoint {
    name      = local.default_frontend_endpoint_name
    host_name = local.default_frontend_endpoint
  }

  backend_pool {
    name = "${var.naming_prefix}-${var.environment}-backend-pool"
    backend {
      host_header = azurerm_linux_web_app.starter.default_hostname
      address     = azurerm_linux_web_app.starter.default_hostname
      http_port   = 80
      https_port  = 443
    }
    load_balancing_name = "load-balancing-${var.naming_prefix}-${var.environment}"
    health_probe_name   = "health-probe-${var.naming_prefix}-${var.environment}"
  }

  backend_pool_load_balancing {
    name = "load-balancing-${var.naming_prefix}-${var.environment}"
  }

  backend_pool_health_probe {
    name                = "health-probe-${var.naming_prefix}-${var.environment}"
    enabled             = false
    interval_in_seconds = 30
    probe_method        = "HEAD"
    protocol            = "Https"
  }
  # end: web

  # start: func
  backend_pool {
    name = "${var.naming_prefix}-${var.environment}-func-backend-pool"
    backend {
      host_header = azurerm_linux_function_app.starter.default_hostname
      address     = azurerm_linux_function_app.starter.default_hostname
      http_port   = 80
      https_port  = 443
    }
    load_balancing_name = "load-balancing-${var.naming_prefix}-${var.environment}-func"
    health_probe_name   = "health-probe-${var.naming_prefix}-${var.environment}-func"
  }

  backend_pool_load_balancing {
    name = "load-balancing-${var.naming_prefix}-${var.environment}-func"
  }

  backend_pool_health_probe {
    name                = "health-probe-${var.naming_prefix}-${var.environment}-func"
    enabled             = false
    interval_in_seconds = 30
    probe_method        = "HEAD"
    protocol            = "Https"
  }
  # end: func

  # start: routes
  routing_rule {
    name               = "rule-${var.naming_prefix}-${var.environment}-all-paths"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = [local.default_frontend_endpoint_name]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "${var.naming_prefix}-${var.environment}-backend-pool"
    }
  }

  routing_rule {
    name               = "rule-${var.naming_prefix}-${var.environment}-http-to-https"
    accepted_protocols = ["Http"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = [local.default_frontend_endpoint_name]
    redirect_configuration {
      redirect_protocol = "HttpsOnly"
      redirect_type     = "Found"
    }
  }
  routing_rule {
    name               = "rule-${var.naming_prefix}-${var.environment}-func-paths"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/api/*"]
    frontend_endpoints = [local.default_frontend_endpoint_name]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "${var.naming_prefix}-${var.environment}-func-backend-pool"
    }
  }
  # end: routes
}

resource "azurerm_cosmosdb_account" "starter" {
  name                               = "cdb-${var.naming_prefix}-${var.environment}"
  location                           = var.location
  resource_group_name                = data.azurerm_resource_group.starter.name
  offer_type                         = "Standard"
  access_key_metadata_writes_enabled = false
  local_authentication_disabled      = false

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "starter" {
  name                = var.database_name
  resource_group_name = data.azurerm_resource_group.starter.name
  account_name        = azurerm_cosmosdb_account.starter.name
}

resource "azurerm_cosmosdb_sql_container" "starter" {
  name                = "starter"
  resource_group_name = data.azurerm_resource_group.starter.name
  account_name        = azurerm_cosmosdb_account.starter.name
  database_name       = azurerm_cosmosdb_sql_database.starter.name
  partition_key_path  = "/id"
}

resource "azurerm_storage_account" "starter" {
  name                            = "strg${var.naming_prefix}${var.environment}"
  resource_group_name             = data.azurerm_resource_group.starter.name
  location                        = var.location
  account_tier                    = var.storage_tier
  account_replication_type        = var.storage_replication
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
}
