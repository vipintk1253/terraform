terraform {
  backend "local" {
    path = "/etc/.eks/terraform.tfstate"
  }
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.25.2"
    }
  }
}

data "template_file" "prefix" {
  template = file("/etc/.eks/prefix")
}

data "template_file" "host" {
  template = file("/etc/.eks/host")
}

data "template_file" "cluster_ca_certificate" {
  template = file("/etc/.eks/cluster_ca_certificate")
}

data "template_file" "cluster_name" {
  template = file("/etc/.eks/cluster_name")
}

provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["/etc/.aws/credentials"]
  profile = "default"
}

provider "kubernetes" {
  host                   = "${trimspace(data.template_file.host.rendered)}"
  cluster_ca_certificate = base64decode("${trimspace(data.template_file.cluster_ca_certificate.rendered)}")
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", "${trimspace(data.template_file.cluster_name.rendered)}"]
    command     = "aws"
  }
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
    storage_class_name = "gp2"
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
