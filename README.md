# terraform-azure-starter
Infrastructure as Code ([Terraform](https://www.terraform.io/)) Starter Project for a [Azure Web App](https://azure.microsoft.com/en-us/services/app-service/web/) with [Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-overview) and [Azure Cosmos DB](https://docs.microsoft.com/en-us/azure/cosmos-db/introduction) backend.

This Terraform project creates the following Azure resources:

1. Log Analytics Workspace
1. Application Insights
1. Linux App Service Plans for Web App and Functions
1. Web App
1. Functions App
1. Storage Account
1. Azure Cosmos DB

**Note**: This sample assumes use of local Terraform state, for production scenarios we recommend [storing the Terraform state in Azure Storage](https://docs.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli).

## Prerequisites
### 1. Terraform
[Install Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/azure-get-started)

Example for Chocolatey in Windows 
```
choco install terraform
```

### 2. Microsoft Azure

**a. Resource Group**

This starter assumes that the [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups) for the solution already exists.

You may follow these [instructions to create a resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal#create-resource-groups).

Once created, please note the name of the resource group as you will need it as part of setting up the Terraform variables.

**b. Azure Credentials for Terraform**

Terraform also requires credentials with enough permissions to perform the desired actions (in this case, Contributor access to the resource group created above)

Follow these [instructions to create a new Service Principal](https://docs.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure?tabs=bash#create-a-service-principal).

Once created, please note the client Id and the client secret as you will need it as part of setting up the Terraform variables.
## How to run
TODO: Instructions to configure variables

Navigate to the src folder and execute the following commands:
```
terraform init
```
```
terraform plan
```
```
terraform apply
```
