output "server1_endpoint" {
  description = "Local Server 1 endpoint"
  value       = "http://localhost:8001/hello"
}

output "server2_endpoint" {
  description = "Local Server 2 endpoint"
  value       = "http://localhost:8002/hello"
}

output "k3s_master_public_ip" {
  description = "Public IP of AWS K3s Master (Control Plane)"
  value       = aws_instance.k3s_master.public_ip
}

output "k3s_worker_public_ip" {
  description = "Public IP of AWS K3s Worker Node"
  value       = aws_instance.k3s_worker.public_ip
}

output "k3s_api_server" {
  description = "AWS K3s Kubernetes API Server URL"
  value       = "https://${aws_instance.k3s_master.public_ip}:6443"
}

output "server4_url" {
  description = "Public URL of Server 4 on AWS K3s Cluster"
  value       = "http://${aws_instance.k3s_master.public_ip}:30004/hello"
}

output "server5_url" {
  description = "Public URL of Server 5 on AWS K3s Cluster"
  value       = "http://${aws_instance.k3s_master.public_ip}:30005/hello"
}
