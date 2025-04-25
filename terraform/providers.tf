terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.31.0"
    }
  }

  backend "gcs" {
    bucket = "infra-state-source"
    prefix = "gcs-cdn-test"
  }
}

provider "google" {
  project = "curious-checking-stuff"
  region  = "asia-south1"
}
