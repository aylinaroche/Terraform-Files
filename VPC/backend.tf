terraform {
  backend "s3" {
    bucket = "aylinbucket123"
    key    = "terraform.tfstate"
    dynamodb_table = "table-vpc-aylin"
    region = "us-west-2"
  }
}