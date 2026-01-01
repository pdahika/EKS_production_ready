locals {
  # Common tags
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  })

  # OIDC Provider URL without protocol
  oidc_provider = replace(module.eks.cluster_oidc_issuer_url, "https://", "")

  # Node group common configuration
  node_group_defaults = {
    disk_size      = 50
    disk_type      = "gp3"
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size       = 1
    max_size       = 3
    desired_size   = 1
    update_config = {
      max_unavailable_percentage = 50
    }
  }

  # Merged node groups
  eks_managed_node_groups = {
    for name, config in var.eks_managed_node_groups :
    name => merge(local.node_group_defaults, config)
  }

  # Public API access CIDRs
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access ? var.cluster_endpoint_public_access_cidrs : []

  # Availability zones
  azs = length(var.availability_zones) > 0 ? var.availability_zones : data.aws_availability_zones.available.names
}