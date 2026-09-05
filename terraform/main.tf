terraform {
  backend "local" {
    path = "/var/lib/terraform/devops-ai-platform/terraform.tfstate"
  }

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "aws" {
  region = var.aws_region
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

# --- Local Docker Resources ---

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

# --- AWS EC2 Resources (Server 3) ---

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "server3_sg" {
  name        = "devops-demo-server3-sg"
  description = "Allow inbound traffic to Server 3"

  ingress {
    description = "HTTP API access"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-demo-server3-sg"
  }
}

resource "aws_instance" "server3" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.aws_instance_type
  vpc_security_group_ids      = [aws_security_group.server3_sg.id]
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # Install Docker
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable docker
    systemctl start docker

    # Run Server 3 container
    docker pull ${var.registry}/hello-server3:${var.image_tag} || true
    docker run -d \
      --name terraform-server3 \
      --restart always \
      -p 8000:8000 \
      ${var.registry}/hello-server3:${var.image_tag}
  EOF

  tags = {
    Name = "terraform-server3"
  }
}
