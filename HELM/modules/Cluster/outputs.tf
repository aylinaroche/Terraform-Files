output "config_map_aws_auth" {
  value = "${local.config_map_aws_auth}"
}

output "ClusterAylin" {
  value = "${aws_eks_cluster.ClusterAylin}"
}