# ECR Repositories
resource "aws_ecr_repository" "applications" {
  for_each = toset(["frontend", "backend", "api", "worker", "cron"])

  name = "${var.project_name}/${each.key}"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${each.key}"
  })
}

resource "aws_ecr_lifecycle_policy" "applications" {
  for_each = aws_ecr_repository.applications

  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus   = "tagged"
        tagPrefixList = ["v"]
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }, {
      rulePriority = 2
      description  = "Expire untagged images after 7 days"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 7
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# ArgoCD for GitOps
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true

  values = [
    file("${path.module}/values/argocd-values.yaml")
  ]

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "configs.cm.timeout.reconciliation"
    value = "180s"
  }

  set {
    name  = "configs.params.server.insecure"
    value = "true"
  }

  depends_on = [module.eks]
}

# Jenkins for CI (Optional)
resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = "jenkins"
  create_namespace = true

  set {
    name  = "controller.serviceType"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.servicePort"
    value = "80"
  }

  set {
    name  = "controller.adminUser"
    value = "admin"
  }

  set {
    name  = "controller.adminPassword"
    value = "admin123"  # Change in production!
  }

  set {
    name  = "persistence.size"
    value = "20Gi"
  }

  depends_on = [module.eks]
}

# Create ArgoCD values file
resource "local_file" "argocd_values" {
  count = var.enable_argocd ? 1 : 0

  filename = "${path.module}/values/argocd-values.yaml"
  content = yamlencode({
    server = {
      service = {
        type = "LoadBalancer"
      }
      ingress = {
        enabled = true
        annotations = {
          "kubernetes.io/ingress.class" = "alb"
          "alb.ingress.kubernetes.io/scheme" = "internet-facing"
          "alb.ingress.kubernetes.io/target-type" = "ip"
          "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{ HTTPS = 443 }])
          "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
          "alb.ingress.kubernetes.io/healthcheck-path" = "/"
        }
        hosts = ["argocd.${var.domain_name}"]
      }
    }
    configs = {
      params = {
        "server.insecure" = true
      }
      cm = {
        "timeout.reconciliation" = "180s"
        "applications.resource.exclusions" = |
          - apiGroups:
              - metrics.k8s.io
            kinds:
              - "*"
            clusters:
              - "*"
        "repositories.credentials" = |
          - url: https://github.com/your-org/your-repo
            passwordSecret:
              name: github-token
              key: token
            usernameSecret:
              name: github-token
              key: username
      }
    }
    rbac = {
      policy = |
        g, system:cluster-admins, role:admin
        g, your-org:devops, role:admin
    }
  })
}