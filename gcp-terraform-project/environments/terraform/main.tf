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
locals {
  service_account_credentials = jsondecode(file(var.service_account_key_path))
  custom_service_account_email = local.service_account_credentials.client_email
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

# GCS Бакет для вихідного коду
resource "google_storage_bucket" "source_code_bucket" {
  name                        = "${var.project_id}-${var.source_code_bucket_name_suffix}"
  location                    = var.region 
  uniform_bucket_level_access = true       # Рекомендовано для IAM
  force_destroy               = true       # Дозволяє видалити бакет, навіть якщо він не порожній (обережно!)

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.gcr_api] # Залежність від Cloud Storage API
}

# Cloud Build Тригер
resource "google_cloudbuild_trigger" "pipeline_trigger" {
  provider    = google-beta
  project     = var.project_id
  name        = "canonical-gcs-trigger-test" # Нова унікальна назва
  description = "Canonical GCS trigger structure"
  # location    = var.region # <--- ВИДАЛЕНО ЦЕЙ РЯДОК. Нехай API сам визначить або використає 'global'.

  trigger_template {
    repo_name   = "gs://${google_storage_bucket.source_code_bucket.name}"
    branch_name = ".*" # Заповнювач
    # project_id НЕ вказуємо тут, оскільки repo_name для GCS вже унікальний
  }

  filename = "cloudbuild.yaml" # Вказує на cloudbuild.yaml в корені об'єкта

  included_files = ["**/*.zip"] # Реагуємо тільки на завантаження ZIP архівів

  # Substitutions ПОКИ ЩО НЕ ДОДАЄМО.
  # substitutions = {
  #   "_GKE_CLUSTER_NAME" = google_container_cluster.primary.name
  #   "_GKE_LOCATION"     = google_container_cluster.primary.location
  #   "_IMAGE_NAME"       = "my-app-final-test"
  # }

  # Сервісний акаунт для виконання білду: стандартний SA Cloud Build.
  # Його дозволи вже налаштовані вище.

  depends_on = [
    google_project_service.cloudbuild_api,
    google_storage_bucket.source_code_bucket,
  ]
}