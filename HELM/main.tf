module "Stack-VPC" {
  source = "./modules/VPC"
}

module "Stack-Cluster" {
  source = "./modules/Cluster"
  SubnetsAylin = "${module.Stack-VPC.SubnetsAylin}"
  VPCaylin = "${module.Stack-VPC.VPCaylin}"
}