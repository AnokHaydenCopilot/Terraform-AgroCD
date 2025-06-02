variable "project_id" {
  description = "ID вашого GCP проекту."
  type        = string
  default     = "focused-ion-452816-h5"
}

variable "region" {
  description = "Регіон для розгортання ресурсів."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Зона для розгортання ресурсів (для GKE нод)."
  type        = string
  default     = "us-central1-a" 
}

variable "gke_cluster_name" {
  description = "Назва Kubernetes кластера."
  type        = string
  default     = "tf-demo-cluster"
}

variable "gke_node_machine_type" {
  description = "Тип машини для нод GKE."
  type        = string
  default     = "e2-medium"  #e2-micro хватає на GKE, але не хватає на HELM
  # EST при e2-micro 
  # GKE + pods = 9m
  # Helm = ~24m
}

variable "gke_node_disk_type" {
  description = "Тип диску для нод GKE."
  type        = string
  default     = "pd-balanced"
}

variable "gke_node_disk_size_gb" {
  description = "Розмір диску для нод GKE в ГБ."
  type        = number
  default     = 20
}

variable "gke_node_count" {
  description = "Кількість нод в GKE кластері."
  type        = number
  default     = 1
}

variable "source_code_bucket_name_suffix" {
  description = "Суфікс для назви GCS бакету для вихідного коду. Назва буде: <project_id>-<suffix>"
  type        = string
  default     = "source-code-pipeline"
}

variable "service_account_key_path" {
  description = "Шлях до файлу ключа сервісного акаунту."
  type        = string
  default     = "../../kubernetes-root.json" 
}

variable "image_name_for_pipeline" {
  description = "Назва Docker образу, яка буде використана в Cloud Build."
  type        = string
  default     = "my-simple-gke-app"
}

variable "grafana_admin_password" {
  description = "Пароль для адміністратора Grafana. Змініть на надійний!"
  type        = string
  default     = "YourSecurePassword123!" 
  sensitive   = false
}

