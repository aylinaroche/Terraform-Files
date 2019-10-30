variable "azs" {
  type    = "list"
  default = ["us-west-2a", "us-west-2b"]
}

variable "subnet_cidr" {
  type    = "list"
  default = ["192.169.1.0/24", "192.169.2.0/24"]
}
