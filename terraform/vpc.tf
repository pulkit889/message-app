# Creating VPC
resource "aws_vpc" "message_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  tags = {
    "Name" = "Message App VPC"
  }
}



# variables for Subent CIDRS's and avalability zone 
variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Message App  Public Subnet Cidr List"
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Message App  Pricate Subnet Cidr List"
  default     = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "avaialability zones"
  default     = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

data "aws_availability_zones" "azs" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Adding Subnets
resource "aws_subnet" "public_subnets" {
  count      = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.message_vpc.id
  cidr_block = element(var.public_subnet_cidrs, count.index)

  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "Message App Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count      = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.message_vpc.id
  cidr_block = element(var.private_subnet_cidrs, count.index)
  #ipv6_cidr_block   = element(var.private_subnet_ipv6_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "Message App  Private Subnet ${count.index + 1}"
  }
}

# Adding a internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.message_vpc.id

  tags = {
    "Name" = "Message App  VPC IG"
  }
}

# Adding Separate route table for Public Subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.message_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    "Name" = "Message App  Public Route Table"
  }
}

resource "aws_route_table_association" "public_subnets_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

# Configuration for NAT gateway
resource "aws_eip" "nat_ip" {
  domain = "vpc"
  tags = {
    "Name" = "Message App  VPC NAT IP"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  subnet_id     = element(aws_subnet.public_subnets[*].id, 0)
  allocation_id = aws_eip.nat_ip.allocation_id
}

# Creating route table for Private Subnets with nat gateway
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.message_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    "Name" = "Message App  Private Route Table"
  }
}

resource "aws_route_table_association" "private_subnets_asso" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.private_route_table.id
}


output "vpc_id" {
  value = aws_vpc.message_vpc.id
}

output "public_subnets" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnets" {
  value = aws_subnet.private_subnets[*].id
}
