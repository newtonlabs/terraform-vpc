output "ip" {
  value = aws_instance.bastion.public_ip
}

output "static_ip" {
  value = aws_eip.default.public_ip
}

