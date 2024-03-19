#terraform main code for linux server
terraform {
  backend "local" {
    path = "/etc/.azure/azure.linux.vm.terraform.tfstate"
  }
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.61.0"
    }
  }
}

data "template_file" "prefix" {
  template = file("/etc/.azure/prefix")
}

data "template_file" "client_id" {
  template = file("/etc/.azure/client_id")
}

data "template_file" "tenant_id" {
  template = file("/etc/.azure/tenant_id")
}

data "template_file" "sub_id" {
  template = file("/etc/.azure/sub_id")
}

provider "azurerm" {
  features {}
  client_certificate_path = "/etc/.azure/mycert.pfx"
  subscription_id = "${trimspace(data.template_file.sub_id.rendered)}"
  client_id = "${trimspace(data.template_file.client_id.rendered)}"
  tenant_id = "${trimspace(data.template_file.tenant_id.rendered)}"
}

resource "azurerm_resource_group" "main" {
  name     = "${trimspace(data.template_file.prefix.rendered)}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${trimspace(data.template_file.prefix.rendered)}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "${trimspace(data.template_file.prefix.rendered)}-sn"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "main" {
  name                = "${trimspace(data.template_file.prefix.rendered)}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "${trimspace(data.template_file.prefix.rendered)}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${trimspace(data.template_file.prefix.rendered)}-web-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  admin_password                  = "P@ssw0rd1234!"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

