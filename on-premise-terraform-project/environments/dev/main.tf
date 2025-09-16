terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }
    argocd = {
      source  = "oboukili/argocd"
      version = ">= 5.0.0"
    }
  }
}
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "docker-desktop"
  }
}
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.51.2"
  
  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd,
  ]
}
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
  depends_on = [helm_release.argocd]
}

data "kubernetes_secret" "argocd_initial_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }
  depends_on = [helm_release.argocd]
}

provider "argocd" {
  server_addr = "${data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname}:${data.kubernetes_service.argocd_server.spec[0].port[0].port}"
  username    = "admin"
  password    = data.kubernetes_secret.argocd_initial_admin_secret.data.password
  insecure    = true
}

resource "argocd_application" "my_simple_app" {
  metadata {
    name      = "my-simple-app"
    namespace = "argocd"
  }

  spec {
    project = "default"

    source {
      repo_url        = "https://github.com/AnokHaydenCopilot/Terraform-AgroCD"
      path            = "on-premise-terraform-project/source_code_for_pipeline/kubernetes"
      target_revision = "HEAD"
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "default"
    }

    sync_policy {
      automated {
        prune = true
      }
    }
  }

  depends_on = [helm_release.argocd]
}