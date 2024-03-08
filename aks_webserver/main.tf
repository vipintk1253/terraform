terraform {
  backend "local" {
    path = "/etc/.azure/aks.webserver.terraform.tfstate"
  }
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.25.2"
    }
  }
}

provider "kubernetes" {
  config_path = "/etc/.azure/aks_config"
}

data "template_file" "prefix" {
  template = file("/etc/.azure/prefix")
}

resource "kubernetes_deployment" "example" {
  metadata {
    name = "${trimspace(data.template_file.prefix.rendered)}-apache-webserver"
    labels = {
      app = "${trimspace(data.template_file.prefix.rendered)}-apache-webserver"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "${trimspace(data.template_file.prefix.rendered)}-apache-webserver"
      }
    }

    template {
      metadata {
        labels = {
          app = "${trimspace(data.template_file.prefix.rendered)}-apache-webserver"
        }
      }

      spec {
        container {
          image = "smehta26/apache:centos"
          name  = "${trimspace(data.template_file.prefix.rendered)}-apache-webserver"
        }
      }
    }
  }
}

resource "kubernetes_service" "apache" {
  metadata {
    name = "${trimspace(data.template_file.prefix.rendered)}-apache-webserver"
  }
  spec {
    selector = {
      app = kubernetes_deployment.example.metadata.0.labels.app
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
  wait_for_load_balancer = false
}
