# FLASK APP MICROSERVICE TASK

# Main.tf File

This repository contains the `main.tf` file, which is a part of the infrastructure provisioning code for **flask_app_microservice**.

## Description

The `main.tf` file is written in HashiCorp Configuration Language (HCL) and is used with Terraform to define and provision the infrastructure required for deploying **flask_app_microservice** on **AWS**.

## Contents

The `main.tf` file includes the following resources and configurations:

- **AWS Resources**: Configuration for provisioning resources on Amazon Web Services (AWS), such as VPCs, subnets, EC2 instances, S3 buckets, etc.
- **Terraform Blocks**: Terraform blocks defining the provider, resources, variables, and outputs used in the infrastructure code.
- **Variables**: Definitions of variables used throughout the file, including descriptions and default values.
- **Outputs**: Definitions of outputs that provide information about the provisioned infrastructure.

## Usage

To use the `main.tf` file:

1. Install Terraform on your local machine.
2. Clone or download this repository.
3. Customize the variables in `variables.tf` file as per your requirements.
4. Run `terraform init` to initialize the working directory containing the Terraform configuration files.
5. Run `terraform plan` to create an execution plan.
6. Run `terraform apply` to apply the changes required to reach the desired state of the configuration.

## Contributing

Contributions are welcome! If you find any issues or want to contribute to the improvement of this `main.tf` file, feel free to open an issue or submit a pull request.

## License

This `main.tf` file is distributed under the [MIT License](LICENSE).


## Deployment

To deploy this project the following are required.

- awscli
- terraform
- Docker
- kubectl
- VPC
- EKS
- ECR
- S3 AND DYNAMODB (for terraform statefile tracking)
```bash
test.tf
```

