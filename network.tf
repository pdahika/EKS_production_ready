# Calico for Network Policies
resource "helm_release" "calico" {
  name       = "calico"
  repository = "https://projectcalico.docs.tigera.io/charts"
  chart      = "tigera-operator"
  namespace  = "tigera-operator"
  create_namespace = true

  set {
    name  = "installation.registry"
    value = "quay.io"
  }

  depends_on = [module.eks]
}

# Network Policies
resource "kubectl_manifest" "default_deny_all" {
  yaml_body = yamlencode({
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "default-deny-all"
      namespace = "default"
    }
    spec = {
      podSelector = {}
      policyTypes = ["Ingress", "Egress"]
    }
  })

  depends_on = [helm_release.calico]
}

resource "kubectl_manifest" "allow_dns" {
  yaml_body = yamlencode({
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "allow-dns"
      namespace = "default"
    }
    spec = {
      podSelector = {}
      policyTypes = ["Egress"]
      egress = [{
        ports = [{
          port     = 53
          protocol = "UDP"
        }]
      }]
    }
  })

  depends_on = [helm_release.calico]
}

# Service Mesh (Istio)
resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  namespace  = "istio-system"
  create_namespace = true

  depends_on = [module.eks]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  namespace  = "istio-system"

  set {
    name  = "meshConfig.accessLogFile"
    value = "/dev/stdout"
  }

  set {
    name  = "meshConfig.enableTracing"
    value = "true"
  }

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  namespace  = "istio-system"

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  depends_on = [helm_release.istiod]
}