output "ip" {
  value = aws_instance.bastion.public_ip
}

output "testserver_ip" {
  value = aws_instance.testserver.public_ip
}

output "static_ip" {
  value = aws_eip.default.public_ip
}

output "base_url" {
  value = aws_api_gateway_deployment.default.invoke_url
}

