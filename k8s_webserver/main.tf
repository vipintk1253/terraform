terraform {
  backend "local" {
    path = "/etc/.k8s/terraform.tfstate"
  }
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.25.2"
    }
  }
}

provider "kubernetes" {
  config_path = "/etc/.k8s/config"
}

resource "kubernetes_persistent_volume" "example" {
  metadata {
    name = "apache-webserver"
  }
  spec {
    capacity = {
      storage = "2Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      vsphere_volume {
        volume_path = "/mnt/data"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "example" {
  metadata {
    name = "apache-webserver-claim"
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
    name = "apache-webserver"
    labels = {
      app = "apache-webserver"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "apache-webserver"
      }
    }

    template {
      metadata {
        labels = {
          app = "apache-webserver"
        }
      }

      spec {
        container {
          image = "smehta26/apache:alpine"
          name  = "apache-webserver"

          volume_mount {
            mount_path = "/var/www/html"
            name       = "apache-webserver-volume"
          }
        }

        volume {
          name = "apache-webserver-volume"
          persistent_volume_claim {
            claim_name = "${kubernetes_persistent_volume_claim.example.metadata.0.name}"
          }
        }
    
      }
    }
  }
}
