output "MyPublicIP" {
  value = azurerm_linux_virtual_machine.main.public_ip_address
}
