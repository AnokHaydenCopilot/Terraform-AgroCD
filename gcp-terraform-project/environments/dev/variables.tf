variable "project_id" {
  description = "ID вашого GCP проекту."
  type        = string
  default     = "montgomery-461911-u8"
}

variable "region" {
  description = "Регіон для розгортання ресурсів."
  type        = string
  # default     = "us-central1" НЕМА ТЕПЕР КВОТИ
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
  # default     = "pd-balanced"
  default     = "pd-standard"
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

variable "custom_vpc_name" {
  description = "Назва для кастомної VPC мережі."
  type        = string
  default     = "gke-custom-vpc"
}

variable "gke_subnet_name" {
  description = "Назва для підмережі GKE."
  type        = string
  default     = "gke-primary-subnet"
}

variable "gke_subnet_ip_cidr" {
  description = "Основний IP CIDR діапазон для підмережі GKE (для нод)."
  type        = string
  default     = "10.10.0.0/20" 
}

variable "gke_pods_ip_cidr_name" {
  description = "Назва вторинного діапазону для GKE Pods."
  type        = string
  default     = "gke-pods-range"
}

variable "gke_pods_ip_cidr" {
  description = "Вторинний IP CIDR діапазон для GKE Pods."
  type        = string
  default     = "10.20.0.0/16" 
}

variable "gke_services_ip_cidr_name" {
  description = "Назва вторинного діапазону для GKE Services."
  type        = string
  default     = "gke-services-range"
}

variable "gke_services_ip_cidr" {
  description = "Вторинний IP CIDR діапазон для GKE Services."
  type        = string
  default     = "10.30.0.0/20" 
}

variable "gke_node_network_tag" {
  description = "Мережевий тег для нод GKE, для застосування правил брандмауера."
  type        = string
  default     = "gke-node"
}