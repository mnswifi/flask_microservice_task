locals {
  region = "us-east-1"
  name   = "flask-eks-cluster"
  vpc_cidr = "10.23.0.0/16"
  azs      = ["us-east-1a", "us-east-1b"]
  public_subnets  = ["10.23.1.0/24", "10.23.2.0/24"]
  private_subnets = ["10.23.3.0/24", "10.23.4.0/24"]
  # intra_subnets   = ["10.123.5.0/24", "10.123.6.0/24"]
}

provider "aws" {
  region = var.region
}
