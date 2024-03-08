output "PrivateIP" {
  value = azurerm_virtual_machine.example.private_ip_address
}

output "PublicIP" {
  value = azurerm_virtual_machine.example.public_ip_address
}

output "UserName" {
  value = azurerm_virtual_machine.example.admin_username
}

output "Password" {
  value = azurerm_virtual_machine.example.admin_password
  sensitive = true
}
