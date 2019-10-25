terraform {
  backend "s3" {
    bucket = "aylinbucket123"
    key    = "terraform.tfstate"
    dynamodb_table = "tableStateVPC"
    region = "us-west-2"
  }
}