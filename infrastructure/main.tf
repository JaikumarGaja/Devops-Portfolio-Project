terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

variable "mongo_uri" {
  description = "MongoDB Connection String"
  type        = string
  sensitive   = true
}

provider "aws" {
  region = "ap-south-1"
}

# 1. Open the necessary ports
# resource "aws_security_group" "main_sg" {
#   name        = "flask_express_sg"
#   description = "Allow SSH, Express (4000), and Flask (5000)"

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
  
#   ingress {
#     from_port   = 4000  
#     to_port     = 4000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
  
#   ingress {
#     from_port   = 5000
#     to_port     = 5000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow SSH and Jenkins (8080)"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Find the latest Ubuntu image
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 3. Create the empty server
# resource "aws_instance" "app_server" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.main_sg.id]
#   key_name = "aws-assignment-key"

#   user_data = templatefile("form-setup.tftpl", {
#   mongo_uri_secret = var.mongo_uri
# })

#   tags = {
#     Name = "App-Server"
#   }
# }

resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name = "aws-assignment-key"

  user_data = templatefile("jenkins-setup.tftpl", {
  })

  tags = {
    Name = "Jenkins-Server"
  }
}

# 4. Output the IP address to your terminal
# output "public_ip" {
#   description = "The public IP of the EC2 instance"
#   value       = aws_instance.app_server.public_ip
# }

output "jenkins_public_ip" {
  description = "The public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_server.public_ip
}

# 1. Build a custom, EKS-optimized VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["ap-south-1a", "ap-south-1b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  # CRITICAL: Without these two, worker nodes cannot resolve the EKS cluster endpoint
  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name    = "devops-portfolio-cluster-v3"
  kubernetes_version = "1.30" # Stable LTS version

  endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  eks_managed_node_groups = {
    app_nodes = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.medium"] 
      
      associate_public_ip_address = true
    }
  }
}