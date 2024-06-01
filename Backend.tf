terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
    
}

backend "s3" {
    bucket = "flask-eks-task-tfstate"
    key = "state/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "flask_eks_lockid"
}
}