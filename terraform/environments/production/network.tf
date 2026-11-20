data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  private_azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

data "aws_subnet" "nat_public" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = local.private_azs[0]
  default_for_az    = true
}

resource "aws_subnet" "private" {
  count             = length(local.private_azs)
  vpc_id            = data.aws_vpc.default.id
  availability_zone = local.private_azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]

  tags = {
    Name = "${var.app_name}-${var.environment}-private-${local.private_azs[count.index]}"
  }
}

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id

  tags = {
    Name = "${var.app_name}-${var.environment}-private"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Lambda ENIs have no public address, so outbound traffic (OAuth providers, SQS)
# goes through a NAT instance. S3 uses the free gateway endpoint instead.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = data.aws_vpc.default.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
}

resource "aws_vpc_security_group_egress_rule" "app_egress" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.app_name}-${var.environment}-nat"
  }
}

module "fck_nat" {
  source  = "RaJiska/fck-nat/aws"
  version = "1.6.1"

  name                = "${var.app_name}-${var.environment}-nat"
  vpc_id              = data.aws_vpc.default.id
  subnet_id           = data.aws_subnet.nat_public.id
  instance_type       = "t4g.nano"
  ha_mode             = true
  update_route_tables = true
  route_tables_ids    = { private = aws_route_table.private.id }
  eip_allocation_ids  = [aws_eip.nat.id]
}
