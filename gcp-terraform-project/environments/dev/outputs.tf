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
