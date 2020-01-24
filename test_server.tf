# Create a standard VPC
resource "aws_vpc" "testserver" {
  cidr_block = "10.0.0.0/16"

  instance_tenancy     = var.tenancy
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Attach an IGW
resource "aws_internet_gateway" "testserver_igw" {
  vpc_id = aws_vpc.testserver.id
}

# Create a public subnet
resource "aws_subnet" "testserver_dmz" {
  vpc_id     = aws_vpc.testserver.id
  cidr_block = "10.0.1.0/24"

  # For now each instance can have a public IP
  map_public_ip_on_launch = true
}

# Define a route table with IGW for the Publix
resource "aws_route_table" "testserver_dmz" {
  vpc_id = aws_vpc.testserver.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.testserver_igw.id
  }
}

# Attach the route and the subnet
resource "aws_route_table_association" "testserver_dmz" {
  subnet_id      = aws_subnet.testserver_dmz.id
  route_table_id = aws_route_table.testserver_dmz.id
}

# Security group definitions
# base    - single base for all instances
# dmz     - ssh access on the bastion and into the private
resource "aws_security_group" "testserver_base" {
  name        = "${var.project_name}/testserver_base"
  description = "Managed by Terraform"
  vpc_id      = aws_vpc.testserver.id
}

resource "aws_security_group" "testserver_dmz" {
  name        = "${var.project_name}/testserver_dmz"
  description = "Managed by Terraform"
  vpc_id      = aws_vpc.testserver.id
}

resource "aws_security_group_rule" "public_to_testserver" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  cidr_blocks = [
    var.my_ip,
  ]
  security_group_id = aws_security_group.testserver_dmz.id
}

resource "aws_security_group_rule" "testserver_to_world" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.testserver_dmz.id
}

resource "aws_security_group_rule" "whitelist_to_testserver" {
  type      = "ingress"
  from_port = 8080
  to_port   = 8080
  protocol  = "tcp"
  cidr_blocks = [
    "${aws_eip.default.public_ip}/32",
    var.my_ip
  ]
  security_group_id = aws_security_group.testserver_dmz.id
}

# Create the server
# https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-up-node-on-ec2-instance.html
# https://www.npmjs.com/package/json-server
resource "aws_instance" "testserver" {
  ami           = "ami-062f7200baf2fa504"
  instance_type = "t1.micro"
  subnet_id     = aws_subnet.testserver_dmz.id

  vpc_security_group_ids = [
    aws_security_group.testserver_base.id,
    aws_security_group.testserver_dmz.id,
  ]

  key_name = aws_key_pair.default.key_name
}