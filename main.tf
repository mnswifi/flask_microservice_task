# main.tf

data "aws_availability_zones" "available" {}

resource "aws_ecr_repository" "flask_eks_docker_image" {
    name = "flask_eks_docker_image"
}


resource "aws_vpc" "flask_eks_vpc" {
    cidr_block           = var.vpc_block
    enable_dns_hostnames = true
    enable_dns_support   = true
    tags                 = { Name = "flask_eks_vpc" }
}

resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.flask_eks_vpc.id
    tags   = { Name = "flask-eks-gw" }
}

resource "aws_route_table" "flask_pub_rt" {
    vpc_id = aws_vpc.flask_eks_vpc.id
    tags = { Name = "Public Route Table" }
}

resource "aws_route" "public" {
    route_table_id         = aws_route_table.flask_pub_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_subnet" "public_subnets" {
    count              = length(var.public_subnet_cidrs)
    vpc_id             = aws_vpc.flask_eks_vpc.id
    cidr_block         = var.public_subnet_cidrs[count.index]
    availability_zone  = element(var.azs, count.index)
    map_public_ip_on_launch = true
    tags               = { Name = "Public Subnet ${count.index + 1}" }
}

resource "aws_subnet" "private_subnets" {
    count    = length(var.private_subnet_cidrs)
    vpc_id   = aws_vpc.flask_eks_vpc.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = element(var.azs, count.index)
    tags     = { Name = "Private Subnet ${count.index + 1}" }
}

resource "aws_route_table_association" "public_associations" {
    count       = length(aws_subnet.public_subnets)
    subnet_id   = aws_subnet.public_subnets[count.index].id
    route_table_id = aws_route_table.flask_pub_rt.id
}

resource "aws_security_group" "control_plane_sg" {
    vpc_id = aws_vpc.flask_eks_vpc.id

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "flask-eks-ControlPlaneSG" }
}

resource "aws_security_group" "node_sg" {
    vpc_id = aws_vpc.flask_eks_vpc.id

    ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "flask-eks-NodeSG" }
}

resource "aws_eks_cluster" "flask_app_eks_cluster" {
    name     = var.cluster_name
    role_arn = aws_iam_role.eks_cluster_role.arn

    vpc_config {
        subnet_ids         = concat(aws_subnet.public_subnets[*].id, aws_subnet.private_subnets[*].id)
        security_group_ids = [aws_security_group.node_sg]
        endpoint_public_access = true
        endpoint_private_access = true
    }

    depends_on = [aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy]
}

resource "aws_eks_node_group" "public_workers" {
    cluster_name    = aws_eks_cluster.flask_app_eks_cluster.name
    node_group_name = "EKS-public-workers"
    node_role_arn   = aws_iam_role.eks_node_group_role.arn
    subnet_ids      = [for i in range(length(var.public_subnet_cidrs)) : aws_subnet.public_subnets[i].id]

    scaling_config {
        desired_size = 2
        max_size     = 2
        min_size     = 2
    }

    instance_types  = ["t2.micro"]
    ami_type        = "AL2_x86_64"
    disk_size       = 20

    depends_on = [
        aws_iam_role_policy_attachment.eks_node_group_AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.eks_node_group_AmazonEC2ContainerRegistryReadOnly,
        aws_iam_role_policy_attachment.eks_node_group_AmazonEKS_CNI_Policy
    ]
}

resource "aws_eks_node_group" "private_workers" {
    cluster_name    = aws_eks_cluster.flask_app_eks_cluster.name
    node_group_name = "EKS-private-workers"
    node_role_arn   = aws_iam_role.eks_node_group_role.arn
    subnet_ids      = aws_subnet.private_subnets[*].id # [for i in range(length(var.private_subnet_cidrs)) : aws_subnet.private_subnets[i].id]

    scaling_config {
        desired_size = 1
        max_size     = 1
        min_size     = 1
    }

    instance_types  = ["t2.micro"]
    ami_type        = "AL2_x86_64"
    capacity_type   = "ON_DEMAND"
    disk_size       = 20

    depends_on = [
        aws_iam_role_policy_attachment.eks_node_group_AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.eks_node_group_AmazonEC2ContainerRegistryReadOnly,
        aws_iam_role_policy_attachment.eks_node_group_AmazonEKS_CNI_Policy
    ]
}

resource "aws_iam_role" "eks_cluster_role" {
    name = "eks-cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_group_role" {
    name = "eks-node-group-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = aws_iam_role.eks_node_group_role.name
}



































































































# # main.tf

# data "aws_availability_zones" "available" {}

# resource "aws_ecr_repository" "flask_eks_docker_image" {
#     name = "flask_eks_docker_image"
# }

# resource "aws_vpc" "flask_eks_vpc" {
#     cidr_block           = var.vpc_block
#     enable_dns_hostnames = true
#     enable_dns_support   = true
#     tags                 = { Name = "flask_eks_vpc" }
# }

# resource "aws_internet_gateway" "gw" {
#     vpc_id = aws_vpc.flask_eks_vpc.id
#     tags   = { Name = "flask-eks-gw" }
# }

# resource "aws_route_table" "flask_pub_rt" {
#     vpc_id = aws_vpc.flask_eks_vpc.id

#     # route {
#     #     cidr_block = "0.0.0.0/0"
#     #     gateway_id = aws_internet_gateway.gw.id
#     # }

#     tags = { Name = "Public Route Table" }
# }

# resource "aws_route" "public" {
#     route_table_id         = aws_route_table.flask_pub_rt.id
#     destination_cidr_block = "0.0.0.0/0"
#     gateway_id             = aws_internet_gateway.gw.id
# }

# resource "aws_subnet" "public_subnets" {
#     count              = length(var.public_subnet_cidrs)
#     vpc_id             = aws_vpc.flask_eks_vpc.id
#     cidr_block         = var.public_subnet_cidrs[count.index]
#     availability_zone = element(var.azs, count.index)
#     map_public_ip_on_launch = true
#     tags               = { Name = "Public Subnet ${count.index + 1}" }
# }

# resource "aws_subnet" "private_subnets" {
#     count    = length(var.private_subnet_cidrs)
#     vpc_id   = aws_vpc.flask_eks_vpc.id
#     cidr_block = var.private_subnet_cidrs[count.index]
#     availability_zone = element(var.azs, count.index)
#     tags     = { Name = "Private Subnet ${count.index + 1}" }
# }

# resource "aws_route_table_association" "public_associations" {
#     count       = length(aws_subnet.public_subnets)
#     subnet_id   = aws_subnet.public_subnets[count.index].id
#     route_table_id = aws_route_table.flask_pub_rt.id
# }

# resource "aws_security_group" "control_plane_sg" {
#     vpc_id = aws_vpc.flask_eks_vpc.id
#     tags   = { Name = "flask-eks-ControlPlaneSG" }
# }

# # Configuring EKS

# resource "aws_eks_cluster" "flask_app_eks_cluster" {
#     name     = var.cluster_name
#     role_arn = aws_iam_role.eks_cluster_role.arn

#     vpc_config {
#         subnet_ids = concat(aws_subnet.public_subnets[*].id, aws_subnet.private_subnets[*].id)
#     }

#     depends_on = [aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy]
# }

# resource "aws_eks_node_group" "public_workers" {
#     cluster_name    = aws_eks_cluster.flask_app_eks_cluster.name
#     node_group_name = "EKS-public-workers"
#     node_role_arn   = aws_iam_role.eks_node_group_role.arn
#     subnet_ids      = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]

#     scaling_config {
#         desired_size = 2
#         max_size     = 2
#         min_size     = 2
#     }

#     instance_types = ["t3.small"]
# }

# resource "aws_eks_node_group" "private_workers" {
#     cluster_name    = aws_eks_cluster.flask_app_eks_cluster.name
#     node_group_name = "EKS-private-workers"
#     node_role_arn   = aws_iam_role.eks_node_group_role.arn
#     subnet_ids      = [aws_subnet.private_subnets[0].id, aws_subnet.private_subnets[1].id]

#     scaling_config {
#         desired_size = 1
#         max_size     = 1
#         min_size     = 1
#     }

#     instance_types     = ["t3.small"]
#     ami_type           = "AL2_x86_64"
#     capacity_type      = "ON_DEMAND"
#     disk_size          = 20
# }

# resource "aws_iam_role" "eks_cluster_role" {
#   name = "eks-cluster-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "eks.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.eks_cluster_role.name
# }

# resource "aws_iam_role" "eks_node_group_role" {
#   name = "eks-node-group-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks_node_group_role.name
# }

# resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_node_group_role.name
# }

# resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks_node_group_role.name
# }



































































