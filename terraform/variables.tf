variable "app_version" {
  description = "Docker image version"
  type        = string
  default     = "2.0"
}

variable "aws_region" {
  description = "AWS region for EC2 instance"
  type        = string
  default     = "us-east-1"
}

variable "aws_instance_type" {
  description = "EC2 instance type for Server 3"
  type        = string
  default     = "t3.micro"
}
