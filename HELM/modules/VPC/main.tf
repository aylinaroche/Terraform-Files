resource "aws_vpc" "VPCaylin" {
  cidr_block           = "192.169.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "VPCaylin"
  }
}

resource "aws_subnet" "SubnetsAylin" {
  count                   = "${length(var.azs)}"
  vpc_id                  = "${aws_vpc.VPCaylin.id}"
  cidr_block              = "${element(var.subnet_cidr, count.index)}"
  availability_zone       = "${element(var.azs, count.index)}"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Subnet${count.index + 1}-Aylin"
  }
}

resource "aws_internet_gateway" "IGaylin" {
  vpc_id = "${aws_vpc.VPCaylin.id}"

  tags = {
    Name = "IGaylin"
  }
}

resource "aws_route_table" "PublicRouteTableAylin" {
  vpc_id = "${aws_vpc.VPCaylin.id}"
  tags = {
    Name = "PublicRouteTableAylin"
  }
}

resource "aws_route" "RouteAylin" {
  route_table_id         = "${aws_route_table.PublicRouteTableAylin.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.IGaylin.id}"
  depends_on             = ["aws_route_table.PublicRouteTableAylin"]
}

resource "aws_route_table_association" "RTASubnetAylin" {
  count          = "${length(var.azs)}"
  subnet_id      = "${element(aws_subnet.SubnetsAylin.*.id, count.index)}"
  route_table_id = "${aws_route_table.PublicRouteTableAylin.id}"
}
