output "instance_ip" {
  description = "The IP address of the created instance."
  value       = google_compute_instance.example_instance.network_interface[0].access_config[0].nat_ip
}

output "instance_id" {
  description = "The ID of the created instance."
  value       = google_compute_instance.example_instance.id
}