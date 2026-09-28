terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.0.0"
    }
  }
}

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "mongo_uri" {
  description = "MongoDB Connection String"
  type        = string
  sensitive   = true
}

provider "aws" {
  region = "ap-south-1"
}

provider "github" {
  token = var.github_token
}

# resource "aws_vpc" "main_vpc" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true
# }

# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main_vpc.id
# }

# resource "aws_subnet" "public_subnet" {
#   vpc_id                  = aws_vpc.main_vpc.id
#   cidr_block              = "10.0.1.0/24"
#   map_public_ip_on_launch = true 
#   availability_zone       = "ap-south-1a"
# }

# resource "aws_route_table" "public_rt" {
#   vpc_id = aws_vpc.main_vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }
# }

# resource "aws_route_table_association" "public_assoc" {
#   subnet_id      = aws_subnet.public_subnet.id
#   route_table_id = aws_route_table.public_rt.id
# }

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
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = "aws-assignment-key"

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

# output "jenkins_public_ip" {
#   description = "The public IP of the Jenkins EC2 instance"
#   value       = aws_instance.jenkins_server.public_ip
# }

# 1. Build a custom, EKS-optimized VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # version = "~> 5.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["ap-south-1a", "ap-south-1b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  map_public_ip_on_launch = true

  # CRITICAL: Without these two, worker nodes cannot resolve the EKS cluster endpoint
  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.26.0"

  name               = "devops-portfolio-cluster-v3"
  kubernetes_version = "1.36" # Stable LTS version

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true

  # THE FIX: Open the NodePort to the public internet
  node_security_group_additional_rules = {
    ingress_nodeport = {
      description = "Allow public access to frontend NodePort"
      protocol    = "tcp"
      from_port   = 30000
      to_port     = 30000
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    #to check the public access to the backend, we can open the backend port as well
    ingress_backend = {
      description = "Allow public access to backend"
      protocol    = "tcp"
      from_port   = 30001
      to_port     = 30001
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }

    #Grafana port opened to check the grafana dashboard
    ingress_grafana = {
      description = "Allow public access to Grafana"
      protocol    = "tcp"
      from_port   = 30002
      to_port     = 30002
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  access_entries = {
    jenkins_admin = {
      principal_arn = aws_iam_role.jenkins_role.arn
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets


  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }

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

# 1. Create the IAM Role for Jenkins
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins_eks_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# 2. Allow Jenkins to read EKS cluster info
resource "aws_iam_role_policy" "jenkins_eks_policy" {
  name = "jenkins_eks_policy"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["eks:DescribeCluster", "eks:ListClusters"]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

# 3. Create the Instance Profile to attach to the EC2 server
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins_profile"
  role = aws_iam_role.jenkins_role.name
}

resource "github_actions_secret" "jenkins_url" {
  repository       = "Devops-Portfolio-Project"
  secret_name      = "JENKINS_URL"
  value = "http://${aws_instance.jenkins_server.public_ip}:8080"
}