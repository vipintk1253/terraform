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

#resource "azurerm_windows_virtual_machine" "example" {
resource "azurerm_virtual_machine" "example" {
  name                = "${trimspace(data.template_file.prefix.rendered)}-win-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  vm_size                = var.size
  network_interface_ids = [
    azurerm_network_interface.example.id
  ]

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${trimspace(data.template_file.prefix.rendered)}-win-vm"
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data    = file("winrm.ps1")
  }

  os_profile_windows_config {
    provision_vm_agent = true
    winrm {
      protocol = "HTTP"
    }
    # Auto-Login's required to configure WinRM
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
    }

    # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = file("FirstLoginCommand.xml")
    }
  }

  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.example.ip_address} > mypublicip"
  }

  provisioner "file" {
    source = "mypublicip"
    destination = "c:/mypublicip"
    connection {
      user = var.admin_username
      password = var.admin_password
      type = "winrm"
      host = azurerm_public_ip.example.ip_address
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
      host = azurerm_public_ip.example.ip_address
    }
  }
}
