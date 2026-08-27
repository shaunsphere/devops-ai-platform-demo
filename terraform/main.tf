terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "devops_demo" {
  name = "devops-demo-network"
}

resource "docker_image" "server1" {
  name = "hello-server1:${var.app_version}"

  build {
    context    = ".."
    dockerfile = "../server1/Dockerfile"
  }
}

resource "docker_image" "server2" {
  name = "hello-server2:${var.app_version}"

  build {
    context    = ".."
    dockerfile = "../server2/Dockerfile"
  }
}

resource "docker_container" "server1" {
  name  = "terraform-server1"
  image = docker_image.server1.image_id

  ports {
    internal = 8000
    external = 8001
  }

  networks_advanced {
    name = docker_network.devops_demo.name
  }
}

resource "docker_container" "server2" {
  name  = "terraform-server2"
  image = docker_image.server2.image_id

  ports {
    internal = 8000
    external = 8002
  }

  networks_advanced {
    name = docker_network.devops_demo.name
  }
}
