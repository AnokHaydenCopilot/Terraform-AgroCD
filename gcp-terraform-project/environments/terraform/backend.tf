terraform {
  backend "gcs" {
    bucket  = "gke-terraform-state-bucket-881" 
    prefix  = "kubernetes-cluster-pipeline/state"  
    credentials = "../../kubernetes-root.json"  
  }
}