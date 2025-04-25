locals {
  website_domain = "static-bucket.apps.gats.dev"
}

resource "google_compute_backend_bucket" "website-backend" {
  name        = "gats-dev-static-content-backend"
  description = "Contains a standard static website"
  bucket_name = google_storage_bucket.website-bucket.name
  enable_cdn  = true
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

# Create url map
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
resource "google_compute_global_address" "default" {
  name = "example-ip"
}

# Create HTTP target proxy
resource "google_compute_target_https_proxy" "default" {
  name    = "http-lb-proxy"
  url_map = google_compute_url_map.default.id

  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.id
  ]
}

# Create forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "http-lb-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_https_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}

resource "google_compute_managed_ssl_certificate" "default" {
  name        = "static-bucket-cert"
  description = "SSL certificate for static bucket"
  managed {
    domains = [local.website_domain]
  }
}
