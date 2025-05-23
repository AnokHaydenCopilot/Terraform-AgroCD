output "instance_ip" {
  description = "The external IP address of the instance."
  value       = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
}

output "instance_id" {
  description = "The ID of the instance."
  value       = google_compute_instance.default.id
}