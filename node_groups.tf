# EKS Managed Node Groups
module "eks_managed_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 19.0"

  for_each = var.eks_managed_node_groups

  name            = each.value.name
  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version

  # Node Group Configuration
  subnet_ids = module.vpc.private_subnets

  # Scaling Configuration
  min_size     = each.value.min_size
  max_size     = each.value.max_size
  desired_size = each.value.desired_size

  # Instance Configuration
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size
  disk_type      = each.value.disk_type

  # AMI Configuration
  ami_type        = "AL2_x86_64"
  platform        = "linux"
  ami_release_version = data.aws_ssm_parameter.eks_ami_release.value

  # IAM Role
  iam_role_arn = aws_iam_role.eks_node_group.arn

  # Update Configuration
  update_config = each.value.update_config

  # Launch Template
  create_launch_template = true
  launch_template_name   = "${var.cluster_name}-${each.value.name}"

  # User Data
  pre_bootstrap_user_data = templatefile("${path.module}/scripts/userdata.sh", {
    cluster_name   = var.cluster_name
    node_group     = each.value.name
    enable_ssm     = true
    enable_cloudwatch_agent = true
  })

  # Labels and Taints
  labels = merge(
    each.value.labels,
    {
      "eks.amazonaws.com/nodegroup" = each.value.name
    }
  )

  taints = each.value.taints

  # Tags
  tags = merge(
    var.tags,
    each.value.labels,
    {
      "k8s.io/cluster-autoscaler/enabled"               = "true"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "Name" = "${var.cluster_name}-${each.value.name}-node"
    }
  )

  depends_on = [
    module.eks,
    aws_iam_role.eks_node_group
  ]
}

# Get latest EKS AMI release version
data "aws_ssm_parameter" "eks_ami_release" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/release_version"
}