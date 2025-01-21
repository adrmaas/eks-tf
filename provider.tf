
terraform {
  backend "s3" {
    bucket         = "terraform-071919116017"
    key            = "eks-tf/test/terraform.state"   # BE SURE TO CHANGE
    region         = "us-east-1"
    use_lockfile   = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}
