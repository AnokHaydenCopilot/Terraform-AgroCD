provider "google" {
  credentials = file(var.service_account_key_path)
  project     = var.project_id
  region      = var.region
}

provider "google-beta" {
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
  project = var.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

# GKE Кластер
resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  location = var.region
  # initial_node_count = 1 # Ми визначаємо node_pool окремо

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
    auto_upgrade = true # Рекомендується для безпеки та оновлень
  }

  node_config {
    machine_type    = var.gke_node_machine_type
    disk_size_gb    = var.gke_node_disk_size_gb
    disk_type       = var.gke_node_disk_type
    preemptible     = false # Якщо потрібні дешевші, але менш надійні ноди
    
    # OAuth scopes для доступу до інших сервісів GCP (наприклад, GCR)
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform" # Повний доступ до GCP API
      # Або більш гранулярні:
      # "https://www.googleapis.com/auth/devstorage.read_only", # Для читання з GCS/GCR
      # "https://www.googleapis.com/auth/logging.write",
      # "https://www.googleapis.com/auth/monitoring",
    ]
  }

  # Для регіональних кластерів, ноди будуть розподілені по зонах автоматично
  # Якщо кластер зональний, потрібно вказати `node_locations = [var.zone]`
}

locals {
  service_account_credentials = jsondecode(file(var.service_account_key_path))
  owner_service_account_email = local.service_account_credentials.client_email
}


resource "google_cloudbuild_trigger" "github_pipeline_trigger" {
  provider    = google-beta
  project     = var.project_id
  name        = "tf-github-final-attempt" # Нова унікальна назва
  description = "GitHub trigger, substitutions at top level, no build block"
  location    = var.region # Або "global", залежно від вашого підключення

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