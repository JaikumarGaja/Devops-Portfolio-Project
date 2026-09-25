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
resource "aws_security_group" "main_sg" {
  name        = "flask_express_sg"
  description = "Allow SSH, Express (4000), and Flask (5000)"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 4000  
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 5000
    to_port     = 5000
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

# Fetch your default AWS network automatically
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Provision the EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name    = "devops-portfolio-cluster"
  kubernetes_version = "1.36"

  # Allows you to run kubectl from your laptop/Jenkins
  endpoint_public_access = true

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  # Create the worker nodes (EC2 instances managed by K8s)
  eks_managed_node_groups = {
    app_nodes = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      # t3.medium is the recommended minimum for EKS to handle system pods
      instance_types = ["t3.medium"] 
    }
  }
}