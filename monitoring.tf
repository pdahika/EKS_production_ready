# CloudWatch Container Insights
resource "helm_release" "cloudwatch_agent" {
  name       = "cloudwatch-agent"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  namespace  = "amazon-cloudwatch"
  create_namespace = true

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.name"
    value = "cloudwatch-agent"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  depends_on = [module.eks]
}

# Prometheus Stack
resource "helm_release" "prometheus_stack" {
  count = var.enable_prometheus_stack ? 1 : 0

  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true

  values = [
    file("${path.module}/values/prometheus-values.yaml")
  ]

  set {
    name  = "grafana.adminPassword"
    value = "admin"  # Change this in production!
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "gp3"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = "50Gi"
  }

  depends_on = [module.eks]
}

# Metrics Server
resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  namespace  = "kube-system"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  depends_on = [module.eks]
}

# AWS X-Ray Daemon
resource "helm_release" "xray" {
  name       = "xray"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-xray-daemon"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  depends_on = [module.eks]
}

# Create Prometheus values file
resource "local_file" "prometheus_values" {
  count = var.enable_prometheus_stack ? 1 : 0

  filename = "${path.module}/values/prometheus-values.yaml"
  content = yamlencode({
    alertmanager = {
      enabled = true
      alertmanagerSpec = {
        storage = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "gp3"
              resources = {
                requests = {
                  storage = "20Gi"
                }
              }
            }
          }
        }
      }
    }
    grafana = {
      enabled = true
      persistence = {
        enabled = true
        storageClassName = "gp3"
        size = "10Gi"
      }
      adminPassword = "admin"
      ingress = {
        enabled = true
        annotations = {
          "kubernetes.io/ingress.class" = "alb"
          "alb.ingress.kubernetes.io/scheme" = "internet-facing"
          "alb.ingress.kubernetes.io/target-type" = "ip"
          "alb.ingress.kubernetes.io/listen-ports" = jsonencode([{ HTTPS = 443 }])
          "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
        }
        hosts = ["grafana.${var.domain_name}"]
      }
    }
    prometheus = {
      prometheusSpec = {
        retention = "30d"
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = "gp3"
              accessModes = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = "50Gi"
                }
              }
            }
          }
        }
        additionalScrapeConfigs = [
          {
            job_name = "aws-services"
            static_configs = [
              {
                targets = ["cloudwatch.amazonaws.com"]
              }
            ]
          }
        ]
      }
    }
  })
}