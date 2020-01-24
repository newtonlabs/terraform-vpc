output "ip" {
  value = aws_instance.bastion.public_ip
}

output "testserver_ip" {
  value = aws_instance.testserver.public_ip
}

output "static_ip" {
  value = aws_eip.default.public_ip
}

