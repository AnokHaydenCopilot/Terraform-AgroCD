provider "google" {
  credentials = file("${path.module}/../../service-account-key.json") # Шлях до ключа
  project     = var.project_id
  region      = var.region
  zone        = var.zone
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

# Бакет для зберігання коду функції
resource "google_storage_bucket" "function_code_bucket" {
  name                        = "function-code-bucket-${random_id.bucket_prefix.hex}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# Архівуємо код функції
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/HTTP_Name_test" # Шлях до папки з кодом функції
  output_path = "${path.module}/function-source.zip"     # Тимчасовий шлях для zip-архіву
}

# Завантажуємо zip-архів у GCS бакет
resource "google_storage_bucket_object" "function_code" {
  name   = "source-archive-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.function_code_bucket.name
  source = data.archive_file.function_source.output_path
}

# Створюємо Cloud Function
resource "google_cloudfunctions_function" "http_function" {
  name        = "http_name_test"
  description = "A simple HTTP Cloud Function"
  runtime     = "python310"
  region      = var.region
  entry_point = "hello_http" # Ім'я функції у файлі main.py

  source_archive_bucket = google_storage_bucket.function_code_bucket.name
  source_archive_object = google_storage_bucket_object.function_code.name
  trigger_http          = true

  available_memory_mb = 128
}

# Дозволяємо публічний доступ до функції
resource "google_cloudfunctions_function_iam_member" "public_access" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.http_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}