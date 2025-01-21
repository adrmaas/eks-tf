resource "aws_vpc" "my" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.my_tags,
    {
      Name = "${var.name}-vpc"
    }
  )
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.my.id
  #count                   = length(var.cidr_public_subnets)
  count                   = var.enable_public_subnets == false ? 0 : length(var.cidr_public_subnets)
  cidr_block              = element(var.cidr_public_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    local.my_tags,
    {
       Name = "${var.name}-${element(var.availability_zones, count.index)}-public-subnet"
    }
  )
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.my.id
  count                   = length(var.cidr_private_subnets)
  cidr_block              = element(var.cidr_private_subnets, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = merge(
    local.my_tags,
    {
       Name = "${var.name}-${element(var.availability_zones, count.index)}-private-subnet"
    }
  )
}

resource "aws_internet_gateway" "my" {
  vpc_id = aws_vpc.my.id
  tags = merge(
    local.my_tags,
    {
      Name = "${var.name}-ig"
    }
  )
}

resource "aws_eip" "my" {
  count      = var.enable_public_subnets ? length(var.availability_zones) : 0
  domain     = "vpc"
  depends_on = [aws_internet_gateway.my]

  tags = merge(
    local.my_tags,
    {
       Name = "${var.name}-nat-eip-${element(var.availability_zones, count.index)}"
    }
  )
}

resource "aws_nat_gateway" "my" {
  count         = var.enable_public_subnets ? length(var.availability_zones) : 0
  allocation_id = element(aws_eip.my.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  depends_on    = [aws_internet_gateway.my]

  tags = merge(
    local.my_tags,
    {
       Name = "${var.name}-nat-gw-${element(var.availability_zones, count.index)}"
    }
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.my.id
  tags = merge(
    local.my_tags,
    {
       Name = "${var.name}-private-route-table"
       Environment = "${var.environment}"
    }
  )
}

# Conditionally create the public resources if var.enable_public_subnets is true
resource "aws_route_table" "public" {
  count  = var.enable_public_subnets == true ? 1 : 0
  vpc_id = aws_vpc.my.id
  tags = merge(
    local.my_tags,
    {
       Name = "${var.name}-public-route-table"
       Environment = "${var.environment}"
    }
  )
}

resource "aws_route" "public_to_igw" {
  count                  = var.enable_public_subnets == true ? 1 : 0
  route_table_id         = element(aws_route_table.public.*.id, 0)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my.id
}

resource "aws_route" "private_to_nat" {
  count                  = var.enable_public_subnets == true ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = element(aws_nat_gateway.my.*.id, 0)
}

resource "aws_route_table_association" "public" {
  count          = var.enable_public_subnets == false ? 0 : length(var.cidr_public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
}