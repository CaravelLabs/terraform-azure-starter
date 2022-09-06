output "web_app_name" { value = azurerm_linux_web_app.starter.name }
output "web_app_hostname" { value = azurerm_linux_web_app.starter.default_hostname }
output "functions_app_name" { value = azurerm_linux_function_app.starter.name }