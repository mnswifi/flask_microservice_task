# variable.tf

variable "region" {
    description = "AWS region"
    default     = "us-east-1"
}

variable "vpc_block" {
    default = "192.168.0.0/16"  # setup for cloudformation template
}

variable "cluster_name" {
    description = "EKS cluster name"
    default     = "flask-eks-cluster"
}

variable "public_subnet_cidrs" {
    description = "List of public subnet CIDRs"
    default     = ["192.168.0.0/18", "192.168.64.0/18"]
}

variable "private_subnet_cidrs" {
    description = "List of private subnet CIDRs"
    default     = ["192.168.128.0/18", "192.168.192.0/18"]
}

variable "azs" {
    description = "List of availability zones"
    default     = ["us-east-1a", "us-east-1b"]
}

variable "flask_image_tag" {
    description = "Docker image tag for the Flask application"
    default     = "latest"
}
