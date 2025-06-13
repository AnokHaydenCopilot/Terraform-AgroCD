terraform {
  backend "gcs" {
    bucket  = "ekzamen-gcp-terraform" 
    prefix  = "kubernetes-cluster-pipeline/state"   
  }
}