module "Stack-VPC" {
  source = "./modules/VPC"
}

module "Stack-Cluster" {
  source       = "./modules/Cluster"
  SubnetsAylin = "${module.Stack-VPC.SubnetsAylin}"
  VPCaylin     = "${module.Stack-VPC.VPCaylin}"
}

module "Stack-Files" {
  source       = "./modules/Files"
  ClusterAylin = "${module.Stack-Cluster.ClusterAylin}"
}
