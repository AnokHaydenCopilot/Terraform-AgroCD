variable "instance_type" {
  description = "The type of instance to use for the development environment."
  type        = string
  default     = "e2-micro"
}

variable "instance_count" {
  description = "The number of instances to launch in the development environment."
  type        = number
  default     = 1
}

variable "region" {
  description = "The GCP region to deploy resources in."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to deploy resources in."
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "The name of the network to use for the development resources."
  type        = string
  default     = "default"
}

variable "subnet_name" {
  description = "The name of the subnet to use for the development resources."
  type        = string
  default     = "default"
}

variable "project_id" {
  description = "ID вашого GCP проєкту"
  type        = string
  default     = "focused-ion-452816-h5"
}

variable "instance_name" {
  description = "The name of the instance."
  type        = string
  default     = "default-instance"
}

variable "image" {
  description = "The image to use for the boot disk."
  type        = string
  default     = "debian-cloud/debian-11"
}

variable "network" {
  description = "The name of the network to attach the instance to."
  type        = string
  default     = "default"
}

variable "bucket" {
  description = "The name of the storage bucket."
  type        = string
  default     = "google_storage_bucket.function_code_bucket.name"
}
