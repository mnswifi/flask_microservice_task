terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 4.18.0"
    }
    
}

backend "s3" {
    bucket = "flask_eks_task_tfstate"
    key = "state/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "flask_eks_lockid"
}
}