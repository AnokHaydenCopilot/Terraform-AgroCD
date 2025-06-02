provider "google" {
  credentials = file(var.service_account_key_path)
  project     = var.project_id
  region      = var.region
}

provider "google-beta" {   #Для тригеру
  credentials = file(var.service_account_key_path)
  project     = var.project_id
  region      = var.region
}

data "google_project" "project" {} # Для отримання project_number

# Включаємо необхідні API
resource "google_project_service" "gke_api" {
  project = var.project_id
  service = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild_api" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "gcr_api" {
  project = var.project_id
  service = "containerregistry.googleapis.com" # Для Google Container Registry
  disable_on_destroy = false
}

resource "google_project_service" "iam_api" {
  project            = var.project_id
  service            = "iam.googleapis.com" # Identity and Access Management (IAM) API
  disable_on_destroy = false
}

resource "google_project_service" "compute_api" {
  project            = var.project_id
  service            = "compute.googleapis.com" # Compute Engine API (потрібен для GKE, мереж, дисків)
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager_api" {
  project            = var.project_id
  service            = "cloudresourcemanager.googleapis.com" # Cloud Resource Manager API (керування проектами)
  disable_on_destroy = false
}

resource "google_project_service" "monitoring_api" {
  project            = var.project_id
  service            = "monitoring.googleapis.com" # Cloud Monitoring API
  disable_on_destroy = false
}

resource "google_project_service" "logging_api" {
  project            = var.project_id
  service            = "logging.googleapis.com" # Cloud Logging API
  disable_on_destroy = false
}

resource "google_project_service" "storage_api" {
  project            = var.project_id
  service            = "storage.googleapis.com" # Cloud Storage API (для GCS бакетів)
  disable_on_destroy = false
}

resource "google_project_service" "pubsub_api" { 
  project            = var.project_id
  service            = "pubsub.googleapis.com" # Cloud Pub/Sub API
  disable_on_destroy = false
}

resource "google_project_service" "eventarc_api" { # Потрібен був для правильної роботи GCS -> Cloud Build в UI
  project            = var.project_id
  service            = "eventarc.googleapis.com" # Eventarc API
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry_api" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com" 
  disable_on_destroy = false
}
resource "google_project_service" "gkehub_api" {
  project            = var.project_id
  service            = "gkehub.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "cloudfunctions_api" {
  project            = var.project_id
  service            = "cloudfunctions.googleapis.com" 
  disable_on_destroy = false
}
resource "google_project_service" "run_api" {
  project            = var.project_id
  service            = "run.googleapis.com" 
  disable_on_destroy = false
}
resource "google_project_service" "serviceusage_api" {
 project            = var.project_id
 service            = "serviceusage.googleapis.com"
 disable_on_destroy = false
}
resource "google_project_service" "networkconnectivity_api" {
 project            = var.project_id
 service            = "networkconnectivity.googleapis.com" # Network Connectivity API
 disable_on_destroy = false
}
resource "google_project_service" "billing_api" {
 project            = var.project_id
 service            = "cloudbilling.googleapis.com" 
 disable_on_destroy = false
}
resource "google_project_service" "iamcredentials_api" {
 project            = var.project_id
 service            = "iamcredentials.googleapis.com" 
 disable_on_destroy = false
}

# GKE Кластер
resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  location = var.region
  deletion_protection = false
  # Видаляємо дефолтний node pool, щоб створити свій з потрібними параметрами
  remove_default_node_pool = true
  initial_node_count       = 1 # Потрібно для remove_default_node_pool

  depends_on = [google_project_service.gke_api]
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.gke_cluster_name}-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location 
  node_count = var.gke_node_count

  management {
    auto_repair  = true
    auto_upgrade = true 
  }

  node_config {
    machine_type    = var.gke_node_machine_type
    disk_size_gb    = var.gke_node_disk_size_gb
    disk_type       = var.gke_node_disk_type
    preemptible     = false # Якщо потрібні дешевші, але менш надійні ноди
    
    # OAuth scopes для доступу до інших сервісів GCP (наприклад, GCR)
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform" # Повний доступ до GCP API
    ]
  }

  # Для регіональних кластерів, ноди будуть розподілені по зонах автоматично
}

locals {
  service_account_credentials = jsondecode(file(var.service_account_key_path))
  owner_service_account_email = local.service_account_credentials.client_email
}

# Тригер пайплайну
resource "google_cloudbuild_trigger" "github_pipeline_trigger" {
  provider    = google
  project     = var.project_id
  name        = "tf-github-update"
  description = "GitHub trigger, update deployment to GKE"
  location    = var.region

  included_files = [
    "gcp-terraform-project/source_code_for_pipeline/**"
  ]

  github {
    owner = "AnokHaydenCopilot"
    name  = "Terraform-Study"
    push {
      branch = "main"
    }
  }

  filename = "gcp-terraform-project/source_code_for_pipeline/cloudbuild.yaml"

  service_account = "projects/${var.project_id}/serviceAccounts/${local.owner_service_account_email}"

  substitutions = {
    "_GKE_CLUSTER_NAME" = google_container_cluster.primary.name
    "_GKE_LOCATION"     = google_container_cluster.primary.location
    "_IMAGE_NAME"       = var.image_name_for_pipeline
  }

  depends_on = [
    google_project_service.cloudbuild_api,
    google_container_cluster.primary,
  ]
}

# Data source для отримання endpoint кластера.
data "google_container_cluster" "primary_for_providers" {
  name     = google_container_cluster.primary.name
  location = google_container_cluster.primary.location
  project  = var.project_id
  depends_on = [google_container_cluster.primary]
}

provider "kubernetes" {

  # Використовуємо kubeconfig
  config_path    = "~/.kube/config" # Стандартний шлях до kubeconfig.
                                    # Якщо ваш kubeconfig в іншому місці, вкажіть правильний шлях.
  config_context = "gke_${var.project_id}_${google_container_cluster.primary.location}_${google_container_cluster.primary.name}"
                   # Назва контексту, яку генерує gcloud.
                   # Перевірте точну назву контексту у вашому ~/.kube/config файлі
                   # або за допомогою `kubectl config current-context`.
                   # Для регіональних кластерів, `google_container_cluster.primary.location` буде регіоном.
}

# Налаштування Helm провайдера
provider "helm" {
  kubernetes {
    # Використовуємо kubeconfig
    config_path    = "~/.kube/config"
    config_context = "gke_${var.project_id}_${google_container_cluster.primary.location}_${google_container_cluster.primary.name}"
  }
}

resource "helm_release" "prometheus_stack" {
  provider = helm

  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "72.6.2"
  namespace  = "monitoring"

  create_namespace = true # Створеться namespace "monitoring"

  # Налаштовуємо Grafana сервіс на тип LoadBalancer
  # та встановлюємо пароль адміністратора Grafana
  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password 
  }
  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  depends_on = [
    google_container_node_pool.primary_nodes, # Кластер має бути готовий
    data.google_container_cluster.primary_for_providers, # Для налаштування helm провайдера
  ]

  timeout = 900 
}