output "server1_endpoint" {
  description = "Local Server 1 endpoint"
  value       = "http://localhost:8001/hello"
}

output "server2_endpoint" {
  description = "Local Server 2 endpoint"
  value       = "http://localhost:8002/hello"
}

output "server3_public_ip" {
  description = "Public IP of AWS Server 3"
  value       = aws_instance.server3.public_ip
}

output "server3_url" {
  description = "Public URL of AWS Server 3"
  value       = "http://${aws_instance.server3.public_ip}:8000/hello"
}
