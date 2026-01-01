
# Global
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "eks-cluster"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "IT-123"
}

# VPC
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "intra_subnet_cidrs" {
  description = "CIDR blocks for intra subnets"
  type        = list(string)
  default     = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
}

# EKS Cluster
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "production-eks"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to EKS API"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to EKS API"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks for public API access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Node Groups
variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions"
  type = map(object({
    name            = string
    instance_types  = list(string)
    min_size        = number
    max_size        = number
    desired_size    = number
    disk_size       = number
    disk_type       = string
    capacity_type   = string
    labels          = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    update_config = object({
      max_unavailable_percentage = number
    })
  }))
  default = {
    general = {
      name            = "general"
      instance_types  = ["t3.medium"]
      min_size        = 2
      max_size        = 5
      desired_size    = 2
      disk_size       = 50
      disk_type       = "gp3"
      capacity_type   = "ON_DEMAND"
      labels = {
        "node-type"   = "general"
        "environment" = "production"
      }
      taints = []
      update_config = {
        max_unavailable_percentage = 50
      }
    }
    spot = {
      name            = "spot"
      instance_types  = ["t3.medium", "t3a.medium"]
      min_size        = 1
      max_size        = 10
      desired_size    = 2
      disk_size       = 50
      disk_type       = "gp3"
      capacity_type   = "SPOT"
      labels = {
        "node-type"   = "spot"
        "environment" = "production"
      }
      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
      update_config = {
        max_unavailable_percentage = 50
      }
    }
  }
}

# Addons
variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Enable External DNS"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Enable Metrics Server"
  type        = bool
  default     = true
}

variable "enable_prometheus_stack" {
  description = "Enable Prometheus Stack"
  type        = bool
  default     = true
}

variable "enable_velero" {
  description = "Enable Velero for backups"
  type        = bool
  default     = true
}

variable "enable_argocd" {
  description = "Enable ArgoCD for GitOps"
  type        = bool
  default     = true
}

# Security
variable "allowed_ssh_ips" {
  description = "List of allowed IPs for SSH access"
  type        = list(string)
  default     = []
}

variable "domain_name" {
  description = "Domain name for applications"
  type        = string
  default     = "example.com"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for load balancers"
  type        = string
  default     = ""
}

# Tags
variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}