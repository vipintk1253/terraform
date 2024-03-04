variable "location" {
  default = "Central India"
}

variable "address_space" {
  default = ["10.0.0.0/16"]
}

variable "address_prefixes" {
  default = ["10.0.2.0/24"]
}

variable "allocation_method" {
  default = "Static"
}

variable "private_ip_address_allocation" {
  default = "Dynamic"
}

variable "size" {
  default = "Standard_F2"
}

variable "admin_username" {
  default = "adminuser"
}

variable "admin_password" {
  default = "PassW0rd@123"
}

variable "os_disk" {
  default = { caching = "ReadWrite", storage_account_type = "Standard_LRS" }
}

variable "source_image_reference" {
  type = map
  default = { publisher = "MicrosoftWindowsServer"
              offer     = "WindowsServer"
              sku       = "2016-Datacenter"
              version   = "latest"
  }
}
