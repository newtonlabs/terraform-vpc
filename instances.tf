
resource "aws_key_pair" "default" {
  key_name   = "public_key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "bastion" {
  ami           = "ami-b8b061d0"
  instance_type = "t1.micro"
  subnet_id     = aws_subnet.dmz.id

  vpc_security_group_ids = [
    aws_security_group.base.id,
    aws_security_group.dmz.id,
  ]

  key_name = aws_key_pair.default.key_name
}

resource "aws_instance" "private" {
  ami           = "ami-b8b061d0"
  instance_type = "t1.micro"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [
    aws_security_group.base.id,
    aws_security_group.private.id,
  ]

  key_name = aws_key_pair.default.key_name
}

