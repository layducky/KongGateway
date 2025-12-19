output "public_ip" {
  value = aws_instance.gateway_server.public_ip
}

output "ssh_command" {
  value = "ssh ubuntu@${aws_instance.gateway_server.public_ip}"
}

output "kong_proxy" {
  value = "http://${aws_instance.gateway_server.public_ip}:8000"
}

output "grafana" {
  value = "http://${aws_instance.gateway_server.public_ip}:3000"
}