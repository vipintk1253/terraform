terraform {
  backend "local" {
    path = "/etc/.azure/azure.win.vm.terraform.tfstate"
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

resource "azurerm_resource_group" "example" {
  name     = "${trimspace(data.template_file.prefix.rendered)}-win-rg"
  location = var.location
}

resource "azurerm_network_security_group" "example" {
  name                = "${trimspace(data.template_file.prefix.rendered)}-win-sg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "${trimspace(data.template_file.prefix.rendered)}-win-sg-rule1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389-6000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "example" {
  name                = "${trimspace(data.template_file.prefix.rendered)}-win-vn"
  address_space       = var.address_space
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "${trimspace(data.template_file.prefix.rendered)}-win-sn"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = var.address_prefixes
}

resource "azurerm_public_ip" "example" {
  name                = "${trimspace(data.template_file.prefix.rendered)}-win-pi"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = var.allocation_method
}

resource "azurerm_network_interface" "example" {
  name                = "${trimspace(data.template_file.prefix.rendered)}-win-ni"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "${trimspace(data.template_file.prefix.rendered)}-win-ipc"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = var.private_ip_address_allocation
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "${trimspace(data.template_file.prefix.rendered)}-win-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  size                = var.size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  boot_diagnostics {
  }

  network_interface_ids = [
    azurerm_network_interface.example.id
  ]

  os_disk {
    caching = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip_address} > mypublicip"
  }

  provisioner "file" {
    source = "mypublicip"
    destination = "/tmp/mypublicip"
    connection {
      user = var.admin_username
      password = var.admin_password
      type = "winrm"
      host = self.public_ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "dir",
    ]
    connection {
      user = var.admin_username
      password = var.admin_password
      type = "winrm"
      host = self.public_ip_address
    }
  }
}
