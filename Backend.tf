backend "s3" {
    bucket = "flask_eks_task-tfstate"
    key = "state/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "flask_eks_lockid"
}