output "jenkins_public_ip_output_file" {
  description = "The public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_server.public_ip
}

# 1. Look up the EC2 instances attached to your EKS cluster
data "aws_instances" "eks_nodes" {
  filter {
    name   = "tag:eks:cluster-name"
    values = [module.eks.cluster_name] # Filters for instances in this specific cluster
  }

  instance_state_names = ["running"]

  # Ensures Terraform waits for the EKS module to finish creating the node group first
  depends_on = [module.eks] 
}

# 2. Output their public IP addresses
output "eks_app_nodes_public_ips" {
  description = "Public IP addresses of the EKS worker nodes"
  value       = data.aws_instances.eks_nodes.public_ips
}