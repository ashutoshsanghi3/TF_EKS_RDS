terraform {
  backend "s3" {
    bucket = "threetier-tf-bucket-ashutosh"
    key    = "us-east-1/terraform.tfstate"
    region = "us-east-1"
  }
}
locals {
  is_cidr_10    = var.my_vpc_cidr == "10.0.0.0/16"
  subnet_map    = local.is_cidr_10 ? var.subnet_config["Vpc10"] : var.subnet_config["Vpc20"]
}

resource "aws_vpc" "main" {
  cidr_block           = var.my_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.stack_name}-My-VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.stack_name}-Internet-Gateway"
  }
}

# Public Subnets
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_map.public_az1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.stack_name}-Public-Subnet-AZ1"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_map.public_az2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.stack_name}-Public-Subnet-AZ2"
  }
}

# Private Subnets
resource "aws_subnet" "private_az1_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_map.private_az1_cidr1
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.stack_name}-Private-Subnet-1-AZ1"
  }
}

resource "aws_subnet" "private_az1_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_map.private_az1_cidr2
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.stack_name}-Private-Subnet-2-AZ1"
  }
}

resource "aws_subnet" "private_az2_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_map.private_az2_cidr1
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.stack_name}-Private-Subnet-1-AZ2"
  }
}

resource "aws_subnet" "private_az2_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_map.private_az2_cidr2
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.stack_name}-Private-Subnet-2-AZ2"
  }
}

# NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.stack_name}-NAT-EIP"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name = "${var.stack_name}-NAT-Gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.stack_name}-Public-RT"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.stack_name}-Private-RT"
  }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Route Table Associations
resource "aws_route_table_association" "pub1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "priv1" {
  subnet_id      = aws_subnet.private_az1_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv2" {
  subnet_id      = aws_subnet.private_az1_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv3" {
  subnet_id      = aws_subnet.private_az2_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv4" {
  subnet_id      = aws_subnet.private_az2_2.id
  route_table_id = aws_route_table.private.id
}

# Security Group for RDS
resource "aws_security_group" "db_sg" {
  name        = "${var.stack_name}-DB-SG"
  description = "Database SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.stack_name}-DB-SG"
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = var.my_db_subnet_group_name
  subnet_ids = [
    aws_subnet.private_az1_2.id,
    aws_subnet.private_az2_2.id,
  ]

  tags = {
    Name = "${var.stack_name}-DBSubnetGroup"
  }
}

# RDS Instance
resource "aws_db_instance" "mysql" {
  identifier             = var.my_db_name
  engine                 = "mysql"
  engine_version         = "8.0.36"
  instance_class         = "db.t3.small"
  allocated_storage      = 20
  db_name                   = var.my_db_name
  username               = var.my_db_username
  password               = var.my_db_password
  multi_az               = true
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot    = true

  tags = {
    Name = "${var.stack_name}-SQLDatabase"
  }

  depends_on = [aws_db_subnet_group.db_subnet_group]
}

# IAM for EKS
resource "aws_iam_role" "eks_cluster_role" {
  name = "EKSClusterRole-TF"

  assume_role_policy = data.aws_iam_policy_document.eks_assume_cluster.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ]

  tags = {
    Name = "${var.stack_name}-EKSCluster-Role"
  }
}

data "aws_iam_policy_document" "eks_assume_cluster" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "eks_node_role" {
  name = "EKSNodeGroupRole-TF"

  assume_role_policy = data.aws_iam_policy_document.eks_assume_node.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]

  inline_policy {
    name = "EKSNodeGroupPolicy"
    policy = data.aws_iam_policy_document.eks_inline_node.json
  }

  tags = {
    Name = "${var.stack_name}-EKS-NodeGroupRole"
  }
}

data "aws_iam_policy_document" "eks_assume_node" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "eks_inline_node" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:DescribeInstances",
      "eks:DescribeNodegroup",
      "eks:CreateNodegroup",
      "eks:DeleteNodegroup",
      "ec2:AttachVolume",
      "ec2:CreateTags",
      "ec2:TerminateInstances",
    ]
    resources = ["*"]
  }
}

# EKS Cluster
resource "aws_eks_cluster" "eks" {
  name     = "MyEKSCluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_az1.id,
      aws_subnet.private_az1_1.id,
      aws_subnet.private_az2_1.id,
      aws_subnet.private_az1_2.id,
      aws_subnet.private_az2_2.id,
    ]
  }

  tags = {
    Name = "${var.stack_name}-EksCluster"
  }

  depends_on = [
    aws_iam_role.eks_cluster_role,
  ]
}

resource "aws_eks_node_group" "nodegroup" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.stack_name}-Node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_az1_1.id, aws_subnet.private_az2_1.id]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = ["t3.medium"]

  tags = {
    Name = "${var.stack_name}-Node-group"
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role.eks_node_role,
  ]
}
