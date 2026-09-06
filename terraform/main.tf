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
  default     = "latest"
}

variable "registry" {
  description = "Container registry"
  type        = string
  default     = "ghcr.io/shaunsphere"
}

# ==============================================================================
# 1. Local Homelab Docker Resources (Cluster 1 / Local Standalone)
# ==============================================================================

resource "docker_network" "devops_demo" {
  name = "devops-demo-network"
}

resource "docker_image" "server1" {
  name = "${var.registry}/hello-server1:${var.image_tag}"
  pull_triggers = [var.image_tag]
}

resource "docker_image" "server2" {
  name = "${var.registry}/hello-server2:${var.image_tag}"
  pull_triggers = [var.image_tag]
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

# ==============================================================================
# 2. AWS Resources: 2-VM K3s Kubernetes Cluster (Cluster 2)
# ==============================================================================

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

# Security Group for AWS K3s Cluster
resource "aws_security_group" "k3s_sg" {
  name        = "devops-demo-k3s-sg"
  description = "Security group for AWS K3s 2-node cluster and ArgoCD communication"

  # Kubernetes API (for ArgoCD / kubectl)
  ingress {
    description = "K3s Kubernetes API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort range for server4, server5, etc.
  ingress {
    description = "Kubernetes NodePort services (server4, server5)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Direct HTTP port range
  ingress {
    description = "Direct HTTP services"
    from_port   = 8000
    to_port     = 8010
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inter-node Flannel VXLAN & Kubelet within Security Group
  ingress {
    description = "Cluster internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-demo-k3s-sg"
  }
}

# EC2 VM 1: K3s Master (Control Plane)
resource "aws_instance" "k3s_master" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.aws_instance_type
  vpc_security_group_ids      = [aws_security_group.k3s_sg.id]
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # Update system packages
    apt-get update -y
    apt-get install -y curl ca-certificates

    # Get Public & Private IP
    TOKEN_IMDS=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)
    PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN_IMDS" http://169.254.169.254/latest/meta-data/public-ipv4 || true)

    # Install K3s Control Plane
    curl -sfL https://get.k3s.io | K3S_TOKEN="${var.k3s_cluster_token}" sh -s - server \
      --tls-san "$${PUBLIC_IP}" \
      --node-name k3s-master \
      --write-kubeconfig-mode 644

    # Wait for K3s service to be ready
    systemctl enable k3s
    systemctl start k3s
  EOF

  tags = {
    Name = "k3s-master-node"
    Role = "control-plane"
  }
}

# EC2 VM 2: K3s Worker Node
resource "aws_instance" "k3s_worker" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.aws_instance_type
  vpc_security_group_ids      = [aws_security_group.k3s_sg.id]
  user_data_replace_on_change = true
  depends_on                  = [aws_instance.k3s_master]

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    apt-get update -y
    apt-get install -y curl ca-certificates

    MASTER_IP="${aws_instance.k3s_master.private_ip}"
    K3S_TOKEN="${var.k3s_cluster_token}"

    # Wait for master API to become ready
    until curl -k -s "https://$${MASTER_IP}:6443" > /dev/null; do
      echo "Waiting for K3s master at $${MASTER_IP}:6443..."
      sleep 5
    done

    # Join cluster as worker agent
    curl -sfL https://get.k3s.io | K3S_URL="https://$${MASTER_IP}:6443" K3S_TOKEN="$${K3S_TOKEN}" sh -s - agent \
      --node-name k3s-worker

    systemctl enable k3s-agent
    systemctl start k3s-agent
  EOF

  tags = {
    Name = "k3s-worker-node"
    Role = "worker"
  }
}
