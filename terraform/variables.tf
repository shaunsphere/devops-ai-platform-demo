variable "app_version" {
  description = "Docker image version"
  type        = string
  default     = "2.0"
}

variable "aws_region" {
  description = "AWS region for EC2 instances"
  type        = string
  default     = "us-east-1"
}

variable "aws_instance_type" {
  description = "EC2 instance type for K3s nodes"
  type        = string
  default     = "t3.small"
}

variable "k3s_cluster_token" {
  description = "Pre-shared token for K3s master and worker node join"
  type        = string
  default     = "devops-demo-secret-k3s-token-2026"
  sensitive   = true
}
