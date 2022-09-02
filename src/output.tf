output "web_app_name" { value = azurerm_app_service.starter.name }
output "web_app_hostname" { value = azurerm_app_service.starter.default_site_hostname }
output "functions_app_name" { value = azurerm_function_app.starter.name }