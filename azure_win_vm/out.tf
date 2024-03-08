output "PrivateIP" {
  value = azurerm_windows_virtual_machine.example.private_ip_address
}

output "PublicIP" {
  value = azurerm_windows_virtual_machine.example.public_ip_address
}

output "UserName" {
  value = var.admin_username
}

output "Password" {
  value = var.admin_password
}
