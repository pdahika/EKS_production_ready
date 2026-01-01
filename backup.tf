# S3 bucket for Velero backups
resource "aws_s3_bucket" "velero_backups" {
  count = var.enable_velero ? 1 : 0

  bucket = "${var.cluster_name}-velero-backups-${random_id.suffix.hex}"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-velero-backups"
  })
}

# Velero IAM Role
resource "aws_iam_role" "velero" {
  count = var.enable_velero ? 1 : 0

  name = "${var.cluster_name}-velero"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" : "sts.amazonaws.com",
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:velero:velero"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "velero" {
  count = var.enable_velero ? 1 : 0

  name        = "${var.cluster_name}-velero"
  description = "Policy for Velero backup/restore"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:CreateTags",
          "ec2:CreateVolume",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = "${aws_s3_bucket.velero_backups[0].arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.velero_backups[0].arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "velero" {
  count = var.enable_velero ? 1 : 0

  role       = aws_iam_role.velero[0].name
  policy_arn = aws_iam_policy.velero[0].arn
}

# Velero Helm Release
resource "helm_release" "velero" {
  count = var.enable_velero ? 1 : 0

  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  namespace  = "velero"
  create_namespace = true

  set {
    name  = "configuration.provider"
    value = "aws"
  }

  set {
    name  = "configuration.backupStorageLocation.name"
    value = "aws"
  }

  set {
    name  = "configuration.backupStorageLocation.bucket"
    value = aws_s3_bucket.velero_backups[0].id
  }

  set {
    name  = "configuration.backupStorageLocation.config.region"
    value = var.aws_region
  }

  set {
    name  = "configuration.volumeSnapshotLocation.name"
    value = "aws"
  }

  set {
    name  = "configuration.volumeSnapshotLocation.config.region"
    value = var.aws_region
  }

  set {
    name  = "initContainers[0].name"
    value = "velero-plugin-for-aws"
  }

  set {
    name  = "initContainers[0].image"
    value = "velero/velero-plugin-for-aws:v1.7.0"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].mountPath"
    value = "/target"
  }

  set {
    name  = "initContainers[0].volumeMounts[0].name"
    value = "plugins"
  }

  set {
    name  = "credentials.existingSecret"
    value = "velero-aws-credentials"
  }

  set {
    name  = "serviceAccount.server.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.server.name"
    value = "velero"
  }

  set {
    name  = "serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.velero[0].arn
  }

  depends_on = [
    module.eks,
    aws_s3_bucket.velero_backups[0],
    aws_iam_role.velero[0]
  ]
}

# Create Velero AWS credentials secret
resource "kubernetes_secret" "velero_aws_credentials" {
  count = var.enable_velero ? 1 : 0

  metadata {
    name      = "velero-aws-credentials"
    namespace = "velero"
  }

  data = {
    "cloud" = <<EOF
[default]
aws_access_key_id=${var.aws_access_key}
aws_secret_access_key=${var.aws_secret_key}
EOF
  }

  type = "Opaque"

  depends_on = [helm_release.velero[0]]
}