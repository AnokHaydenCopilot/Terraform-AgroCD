terraform {
  backend "gcs" {
    bucket      = "random881-terraform-state-bucket" # Ім'я вашого бакета
    prefix      = "terraform/state"                 # Шлях до файлу стану в бакеті
    credentials = "../../service-account-key.json"  # Простий шлях до файлу
  }
}