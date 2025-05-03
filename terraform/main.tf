locals {
  website_domain = "static-bucket.apps.gats.dev"
}

resource "google_storage_bucket" "website-bucket" {
  name     = "gats-dev-static-content-bucket"
  location = var.region

  website {
    main_page_suffix = "index.html"
    not_found_page   = "error.html"
  }
}


resource "google_storage_bucket_iam_member" "allUsers" {
  bucket = google_storage_bucket.website-bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Backend Bucket
# It creates a compute backend by using the storage bucket
# as its source of static files
# Normally you need a service to be added to a url-map,
# this resources converts your Cloud Storage Blob storage
# into an equivalent service that can be attached to a
# Compute URL Map
resource "google_compute_backend_bucket" "website-backend" {
  name        = "gats-dev-static-content-backend"
  description = "Contains a standard static website"
  bucket_name = google_storage_bucket.website-bucket.name
  enable_cdn  = true
}

# Create URL Map
# This creates rules which can get attached to a proxy
# according to which the proxy terminates the SSL connections
# on it and then further down the lines passes those connections
# to individual backend instances
resource "google_compute_url_map" "default" {
  name = "http-lb"

  default_service = google_compute_backend_bucket.website-backend.id

  host_rule {
    hosts        = [local.website_domain]
    path_matcher = "default"
  }

  path_matcher {
    name            = "default"
    default_service = google_compute_backend_bucket.website-backend.id
  }
}

# Reserve IP address
# This IP Address will be attached to the loadbalancer marking
# as the entry point of traffic to it.
resource "google_compute_global_address" "default" {
  name = "example-ip"
}

# GCP Managed SSL Certificate -
# To be provision correctly it requires that the domain name
# is pointed towards the IP address that we procured for the
# website.
resource "google_compute_managed_ssl_certificate" "default" {
  name        = "static-bucket-cert"
  description = "SSL certificate for static bucket"
  managed {
    domains = [local.website_domain]
  }
}

# Create HTTP target proxy
# This HTTPS Proxy is the actual thing which takes the rules
# defined in url map and distribute traffic according to it.
resource "google_compute_target_https_proxy" "default" {
  name    = "http-lb-proxy"
  url_map = google_compute_url_map.default.id

  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.id
  ]
}

# Create forwarding rule
# Creating a global forwarding rule means that you are creating
# the loadbalancer resource.
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "http-lb-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}
