# Create a standard VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  instance_tenancy     = var.tenancy
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}/vpc"
  }
}

# Attach an IGW
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}/default"
  }
}

# Create a public subnet
resource "aws_subnet" "dmz" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"

  # For now each instance can have a public IP
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}/public"
  }
}

# Create a Private subnet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "${var.project_name}/private"
  }
}

# Define a route table with IGW for the Publix
resource "aws_route_table" "dmz" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "${var.project_name}/dmz"
  }
}

# Create a NAT gateway with an EIP for each private subnet to get internet connectivity for
# docker pulls and API calls and such
resource "aws_eip" "default" {
  vpc        = true
  depends_on = [aws_internet_gateway.default]
}

resource "aws_nat_gateway" "gw" {
  subnet_id     = aws_subnet.dmz.id
  allocation_id = aws_eip.default.id
}

# Create a new route table for the private subnet
# And make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Attach the route and the subnet
resource "aws_route_table_association" "dmz" {
  subnet_id      = aws_subnet.dmz.id
  route_table_id = aws_route_table.dmz.id
}

# Security group definitions
# base    - single base for all instances
# dmz     - ssh access on the bastion and into the private
# private - accept ssh from bastion into private
resource "aws_security_group" "base" {
  name        = "${var.project_name}/base"
  description = "Managed by Terraform"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}/base"
  }
}

resource "aws_security_group" "dmz" {
  name        = "${var.project_name}/dmz"
  description = "Managed by Terraform"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}/dmz"
  }
}

resource "aws_security_group" "private" {
  name        = "${var.project_name}/private"
  description = "Managed by Terraform"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}/private"
  }
}

resource "aws_security_group_rule" "public_to_bastion" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  cidr_blocks = [
    var.my_ip,
  ]

  security_group_id = aws_security_group.dmz.id
}

resource "aws_security_group_rule" "bastion_to_private" {
  type      = "egress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"

  security_group_id        = aws_security_group.dmz.id
  source_security_group_id = aws_security_group.private.id
}

resource "aws_security_group_rule" "incoming_from_bastion" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"

  security_group_id        = aws_security_group.private.id
  source_security_group_id = aws_security_group.dmz.id
}

resource "aws_security_group_rule" "bastion_to_world" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.dmz.id
}

# This will traverse the route table and be assigned the static IP for the world
# to understand
resource "aws_security_group_rule" "private_to_world" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.private.id
}


