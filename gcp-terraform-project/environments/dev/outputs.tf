output "gke_cluster_name" {
  description = "Назва створеного GKE кластера."
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "Endpoint GKE кластера."
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gke_cluster_location" {
  description = "Локація (регіон або зона) GKE кластера."
  value       = google_container_cluster.primary.location
}

output "gke_node_pool_name" {
  description = "Назва пулу нод GKE кластера."
  value       = google_container_node_pool.primary_nodes.name
}

output "cloud_build_trigger_id" {
  description = "ID створеного Cloud Build тригера."
  value       = google_cloudbuild_trigger.github_pipeline_trigger.id
}

output "how_to_get_kubeconfig" {
  description = "Команда для отримання kubeconfig файлу для доступу до кластера."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${google_container_cluster.primary.location} --project ${var.project_id}"
}

data "kubernetes_service_v1" "grafana_service" {
  provider = kubernetes 
  metadata {
    name      = "prometheus-stack-grafana" 
    namespace = "monitoring"               
  }
  depends_on = [helm_release.prometheus_stack] 
}

output "grafana_access_info" {
  description = "Інформація для доступу до Grafana."
  value = <<EOT
Grafana доступна за адресою: http://${try(data.kubernetes_service_v1.grafana_service.status[0].load_balancer[0].ingress[0].ip, "PENDING_IP")}
Логін: admin
Пароль: ${var.grafana_admin_password}
Ви можете перевірити статус сервісу командою: kubectl get svc prometheus-stack-grafana -n monitoring
EOT
  depends_on = [data.kubernetes_service_v1.grafana_service]
}
