variable "instance_type" {
  description = "The type of instance to create in GCP."
  type        = string
  default     = "n1-standard-1"
}

variable "region" {
  description = "The GCP region to deploy resources."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to deploy resources."
  type        = string
  default     = "us-central1-a"
}

variable "network" {
  description = "The name of the network to use."
  type        = string
}

variable "subnetwork" {
  description = "The name of the subnetwork to use."
  type        = string
}