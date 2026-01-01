# AWS Configuration
aws_region    = "us-east-1"
environment   = "production"
project_name  = "myapp-eks"
cost_center   = "PROD-001"

# VPC Configuration
vpc_cidr     = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# EKS Configuration
cluster_name = "myapp-production-eks"
cluster_version = "1.28"

# Security - RESTRICT THESE IN PRODUCTION!
cluster_endpoint_public_access_cidrs = ["YOUR_OFFICE_IP/32", "VPN_IP/32"]
allowed_ssh_ips = ["YOUR_OFFICE_IP/32"]

# Node Groups - Production Sizing
eks_managed_node_groups = {
  general = {
    name            = "general"
    instance_types  = ["m5.large", "m5a.large"]
    min_size        = 3
    max_size        = 10
    desired_size    = 3
    disk_size       = 100
    disk_type       = "gp3"
    capacity_type   = "ON_DEMAND"
    labels = {
      "node-type"    = "general"
      "environment"  = "production"
      "workload"     = "general"
    }
    taints = []
    update_config = {
      max_unavailable_percentage = 33
    }
  }
  spot = {
    name            = "spot"
    instance_types  = ["m5.large", "m5a.large", "m5d.large"]
    min_size        = 2
    max_size        = 15
    desired_size    = 2
    disk_size       = 100
    disk_type       = "gp3"
    capacity_type   = "SPOT"
    labels = {
      "node-type"    = "spot"
      "environment"  = "production"
      "workload"     = "batch"
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

# Domain & Certificates
domain_name = "myapp.com"
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxx-xxxx-xxxx"

# Tags
tags = {
  Department   = "Engineering"
  Application  = "MyApp"
  BusinessUnit = "Platform"
  DataClass    = "Confidential"
  Compliance   = "PCI-DSS"
}