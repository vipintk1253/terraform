terraform {
  backend "local" {
    path = "/etc/.aks/terraform.tfstate"
  }
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.25.2"
    }
  }
}

provider "kubernetes" {
  config_path = "/etc/.aks/config"
}

data "template_file" "prefix" {
  template = file("/etc/.aks/prefix")
}

resource "kubernetes_persistent_volume" "example" {
  metadata {
    name = "${trimspace(data.template_file.prefix.rendered)}-apache-webserver"
  }
  spec {
    capacity = {
      storage = "2Gi"
    }
    access_modes = ["ReadWriteMany"]
    storage_class_name = "default"
    persistent_volume_source {
      host_path {
        path = "/mnt/data"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "example" {
  metadata {
    name = "${trimspace(data.template_file.prefix.rendered)}-apache-webserver-claim"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    volume_name = "${kubernetes_persistent_volume.example.metadata.0.name}"
  }
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

          volume_mount {
            mount_path = "/var/www/html"
            name       = "${trimspace(data.template_file.prefix.rendered)}-apache-webserver-volume"
          }

          volume_mount {
            mount_path = "/var/log/httpd"
            name       = "${trimspace(data.template_file.prefix.rendered)}-apache-webserver-volume"
          }
        }

        volume {
          name = "${trimspace(data.template_file.prefix.rendered)}-apache-webserver-volume"
          persistent_volume_claim {
            claim_name = "${kubernetes_persistent_volume_claim.example.metadata.0.name}"
          }
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
      node_port   = 32000
      target_port = 80
    }

    type = "LoadBalancer"
  }
  wait_for_load_balancer = false
}
