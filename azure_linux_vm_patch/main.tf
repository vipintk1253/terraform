resource "azurerm_resource_group" "example" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "${var.prefix}-cluster"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "${var.prefix}-k8s"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = var.size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

resource "local_file" "config" {
  content  = azurerm_kubernetes_cluster.example.kube_config_raw
  filename = "${path.module}/config"
}
