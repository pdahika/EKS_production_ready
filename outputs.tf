output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

output "configure_kubectl" {
  description = "Configure kubectl command"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region} --alias ${module.eks.cluster_name}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "bastion_host_public_ip" {
  description = "Bastion host public IP"
  value       = aws_instance.bastion.public_ip
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.applications : k => v.repository_url }
}

output "velero_backup_bucket" {
  description = "Velero backup bucket name"
  value       = var.enable_velero ? aws_s3_bucket.velero_backups[0].id : null
}

output "grafana_url" {
  description = "Grafana URL"
  value       = var.enable_prometheus_stack ? "https://grafana.${var.domain_name}" : null
}

output "argocd_url" {
  description = "ArgoCD URL"
  value       = var.enable_argocd ? "https://argocd.${var.domain_name}" : null
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${helm_release.jenkins.status.ingress[0].hostname}"
}

output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.eks.id
}