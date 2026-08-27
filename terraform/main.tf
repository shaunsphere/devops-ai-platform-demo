terraform {
  backend "local" {
    path = "/var/lib/terraform/devops-ai-platform/terraform.tfstate"
  }

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

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
}

variable "registry" {
  description = "Container registry"
  type        = string
  default     = "ghcr.io/shaunsphere"
}

resource "docker_network" "devops_demo" {
  name = "devops-demo-network"
}

resource "docker_image" "server1" {
  name = "${var.registry}/hello-server1:${var.image_tag}"

  pull_triggers = [
    var.image_tag
  ]
}

resource "docker_image" "server2" {
  name = "${var.registry}/hello-server2:${var.image_tag}"

  pull_triggers = [
    var.image_tag
  ]
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
