terraform {
  backend "local" {
    path = "/etc/.docker/terraform.tfstate"
  }
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "apache" {
  name = "smehta26/apache:alpine"
  build {
    context = "."
  }
}

resource "docker_container" "apache" {
  name  = "apache"
  image = docker_image.apache.image_id

  ports {
    internal = "80"
    external = "8100"
  }

  volumes {
    container_path = "/var/www/html/index.html"
    host_path      = "${path.module}/index.html"
  }
}
