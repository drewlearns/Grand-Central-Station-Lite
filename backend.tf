terraform {
  backend "s3" {
    bucket  = "terraform-state-339712783646"
    key     = "management/accounts/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
