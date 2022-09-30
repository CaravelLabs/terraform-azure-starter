# You can use a '.tfvars' file to supply values for these variables or provide them at execution time.
# read more here: https://www.terraform.io/docs/configuration/variables.html

variable subscription_id {
  type = string
  description = "The Azure subscription to deploy these resources to"
}

variable tenant_id {
  type = string
  description = "The Azure tenant where the resources are deployed to"
}

variable main_resource_group_name {
  type = string
  description = "The Azure resource group the resources are deployed to"
}

variable client_id {
  type = string
  description = "The AD service principal to use to deploy the resources"
}

variable client_secret {
  type = string
  description = "The AD service principal secret"
}

variable environment {
  type        = string
  description = "solution environment where the resource will be used for. (dev, ci, uat, prod..)"
  default     = "ci"
}

variable location {
  type        = string
  description = "The default Azure region to deploy to"
  default     = "eastus2"
}

variable naming_prefix {
  type        = string
  description = "Prefix used when generating resource names"
  default     = "caravel"
}

variable web_always_on {
  type        = string
  description = "Whether the Web App will be always on"
  default = "false"
}

variable web_tier {
  type        = string
  description = "VM tier for the Web App plan"
  default = "B1"
}

variable api_always_on {
  type        = string
  description = "Whether the API will be always on"
  default = "false"
}

variable api_tier {
  type        = string
  description = "VM size for the API App plan"
  default = "B1"
}

variable storage_tier {
  type        = string
  description = "Azure storage pricing tier"
  default = "Standard"
}

variable storage_replication {
  type        = string
  description = "Azure storage replication type"
  default = "LRS"
}

variable database_name {
  type        = string
  description = "App Cosmos DB database name"
}

variable additional_signalr_cors {
  type        = list
  description = "Additioanl CORS entries for SignalR, this is used mostly for development to allow localhost"
  default     = []
}

variable additional_storage_cors {
  type        = list
  description = "Additioanl CORS entries for storage, this is used mostly for development to allow localhost"
  default     = []
}