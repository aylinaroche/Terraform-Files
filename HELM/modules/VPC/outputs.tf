output "VPCaylin" {
  value = "${aws_vpc.VPCaylin.id}"
}

output "SubnetsAylin" {
  value = "${aws_subnet.SubnetsAylin.*.id}"
}
