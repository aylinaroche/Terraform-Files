terraform {
  backend "s3" {
    bucket = "aylinbucket123"
    key    = "terraform.tfstate"
    dynamodb_table = "table-helm-aylin"
    region = "us-west-2"
  }
}