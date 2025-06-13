provider "google" {
  credentials = file(var.service_account_key_path)
  project     = var.project_id
  region      = var.region
}

data "google_client_config" "default" {} 

# GKE Кластер
resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  # location = var.region НЕМА ТЕПЕР КВОТИ
  location = var.zone
  deletion_protection = false
  # Видаляємо дефолтний node pool, щоб створити свій з потрібними параметрами
  remove_default_node_pool = true
  initial_node_count       = 1 
                                        
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.gke_cluster_name}-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location 
  node_count = var.gke_node_count
  project    = var.project_id

  management {
    auto_repair  = true
    auto_upgrade = true 
  }

  node_config {
    machine_type    = var.gke_node_machine_type
    disk_size_gb    = var.gke_node_disk_size_gb
    disk_type       = var.gke_node_disk_type
    preemptible     = false # Якщо потрібні дешевші, але менш надійні ноди
    
    # OAuth scopes для доступу до інших сервісів GCP 
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform" # Повний доступ до GCP API
    ]
    tags = [var.gke_node_network_tag, var.gke_cluster_name]
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
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
}


resource "google_compute_instance" "default" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = var.network
    access_config {
      // Ephemeral IP
    }
  }
}

resource "google_compute_firewall" "default" {
  name    = "allow-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Генеруємо унікальний префікс для імені бакета
resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "function_code_bucket" {
  name                        = "ekzamen-${random_id.bucket_prefix.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_sql_database_instance" "mysql_demo_db" {
  name = "db"
  deletion_protection = false
  region = "us-central1"
  database_version = "MYSQL_5_7"
  settings {
    tier = "db-f1-micro"
  }
}