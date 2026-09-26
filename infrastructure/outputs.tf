output "jenkins_public_ip_output_file" {
  description = "The public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_server.public_ip
}

output "EKS_cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}
