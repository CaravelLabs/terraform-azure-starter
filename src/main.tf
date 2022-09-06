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

resource "azurerm_app_service_plan" "starter" {
  name                = "asp-${var.naming_prefix}-${var.environment}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.starter.name
  kind                = "linux"
  reserved            = "true"
  sku {
    tier = var.web_tier
    size = var.web_size
  }
}

resource "azurerm_app_service_plan" "starter-func" {
  name                = "asp-func-${var.naming_prefix}-${var.environment}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.starter.name
  kind                = "linux"
  reserved            = "true"
  sku {
    tier = var.api_tier
    size = var.api_size
  }
}

resource "azurerm_app_service" "starter" {
  name                = "web-${var.naming_prefix}-${var.environment}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.starter.name
  app_service_plan_id = azurerm_app_service_plan.starter.id
  https_only          = "true"

  app_settings = {
    API_URL                         = "https://${azurerm_function_app.starter.default_hostname}"
    APPINSIGHTS_INSTRUMENTATIONKEY  = azurerm_application_insights.starter.instrumentation_key
    APPINSIGHTS_ROLENAME            = "web-${var.naming_prefix}-${var.environment}"
    WEBSITE_ENABLE_SYNC_UPDATE_SITE = "true"
  }

  logs {
    failed_request_tracing_enabled  = true
    detailed_error_messages_enabled = true
  }

  site_config {
    always_on        = var.web_always_on
    app_command_line = "NODE_ENV=production npm run start"
    linux_fx_version = "NODE|16-lts"
    ftps_state       = "Disabled"
    http2_enabled    = true
  }
}

resource "azurerm_function_app" "starter" {
  name                       = "func-${var.naming_prefix}-${var.environment}"
  location                   = var.location
  resource_group_name        = data.azurerm_resource_group.starter.name
  app_service_plan_id        = azurerm_app_service_plan.starter-func.id
  storage_account_name       = azurerm_storage_account.starter.name
  storage_account_access_key = azurerm_storage_account.starter.primary_access_key
  os_type                    = "linux"
  version                    = "~3"
  https_only                 = true

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME        = "node"
    WEBSITE_ENABLE_SYNC_UPDATE_SITE = "true"
    WEBSITE_NODE_DEFAULT_VERSION    = "~14"
    WEBSITE_RUN_FROM_PACKAGE        = "1"
    APPINSIGHTS_INSTRUMENTATIONKEY  = azurerm_application_insights.starter.instrumentation_key
    APPINSIGHTS_ROLENAME            = "func-${var.naming_prefix}-${var.environment}"
    COSMOSDB_ENDPOINT               = azurerm_cosmosdb_account.starter.endpoint
    COSMOSDB_KEY                    = azurerm_cosmosdb_account.starter.primary_key
    COSMOSDB_STARTER_CONTAINER      = azurerm_cosmosdb_sql_container.starter.name
    DATABASE_NAME                   = var.database_name
  }

  site_config {
    always_on = var.api_always_on
    cors {
      allowed_origins = [
        "https://functions-staging.azure.com",
        "https://functions.azure.com",
        "https://functions-next.azure.com",
      ]
    }
    linux_fx_version = "NODE|14"
    http2_enabled    = true
  }
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
