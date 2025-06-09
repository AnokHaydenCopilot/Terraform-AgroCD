provider "google" {
  credentials = file(var.service_account_key_path)
  project     = var.project_id
  region      = var.region
}

# data "google_project" "project" {} 
data "google_client_config" "default" {} 

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

resource "google_compute_network" "custom_vpc" {
  project                 = var.project_id
  name                    = var.custom_vpc_name
  auto_create_subnetworks = false 
  routing_mode            = "REGIONAL" 
  depends_on = [
    google_project_service.compute_api 
  ]
}

resource "google_compute_subnetwork" "gke_subnet" {
  project                  = var.project_id
  name                     = var.gke_subnet_name
  ip_cidr_range            = var.gke_subnet_ip_cidr
  network                  = google_compute_network.custom_vpc.id
  region                   = var.region
  private_ip_google_access = true # Дозволяє нодам без зовнішніх IP доступ до Google API

  secondary_ip_range {
    range_name    = var.gke_pods_ip_cidr_name
    ip_cidr_range = var.gke_pods_ip_cidr
  }
  secondary_ip_range {
    range_name    = var.gke_services_ip_cidr_name
    ip_cidr_range = var.gke_services_ip_cidr
  }

  depends_on = [google_compute_network.custom_vpc]
}

resource "google_compute_firewall" "allow_internal_gke_subnet" {
  project = var.project_id
  name    = "${var.custom_vpc_name}-allow-internal-gke"
  network = google_compute_network.custom_vpc.id

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"] 
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"] 
  }
  source_ranges = [var.gke_subnet_ip_cidr, var.gke_pods_ip_cidr, var.gke_services_ip_cidr]
}
# IAP
resource "google_compute_firewall" "allow_ssh_iap_to_gke_nodes" {
  project = var.project_id
  name    = "${var.custom_vpc_name}-allow-ssh-iap"
  network = google_compute_network.custom_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"] # IP діапазон Google IAP для TCP forwarding
  target_tags   = [var.gke_node_network_tag] 
}
# LoadBalancer + Health check
resource "google_compute_firewall" "allow_gclb_health_checks_to_gke_nodes" {
  project = var.project_id
  name    = "${var.custom_vpc_name}-allow-gclb-health-checks"
  network = google_compute_network.custom_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["10256"]
  }
  # IP діапазони Google для Load Balancer'ів та Health Check'ів
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22"]
  target_tags   = [var.gke_node_network_tag]
}

# GKE Кластер
resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name
  # location = var.region НЕМА ТЕПЕР КВОТИ
  location = var.zone
  deletion_protection = false
  # Видаляємо дефолтний node pool, щоб створити свій з потрібними параметрами
  remove_default_node_pool = true
  initial_node_count       = 1 

  network    = google_compute_network.custom_vpc.id 
  subnetwork = google_compute_subnetwork.gke_subnet.id 

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.gke_subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.gke_subnet.secondary_ip_range[1].range_name
  }
                                        
  depends_on = [
    google_project_service.gke_api,
    google_compute_subnetwork.gke_subnet
  ]
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
    google_project_service.cloudbuild_api,
    google_container_cluster.primary,
  ]
}

# Data source для отримання endpoint кластера. (Моя стара версія для kubeconfig)
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

resource "helm_release" "prometheus_stack" {
  provider = helm 

  name       = "prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "72.6.2"
  namespace  = "monitoring"

  create_namespace = true

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
    type  = "string" 
  }
  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  depends_on = [
    google_container_node_pool.primary_nodes,
  ]

  timeout = 900
}