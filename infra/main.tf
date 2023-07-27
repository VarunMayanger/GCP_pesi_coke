# Bucket to store website
resource "google_storage_bucket" "website" {
  name          = "example_pepsi_coke"
  location      = "US"
}

# Making the object public
resource "google_storage_object_access_control" "public_rule" {
  object = google_storage_bucket_object.site_src.name
  bucket = google_storage_bucket.website.name
  role   = "READER"
  entity = "allUsers"
}

# Uplodad html file to bucket
resource "google_storage_bucket_object" "site_src"{
  name   = "index.html"
  source = "../website/index.html"
  bucket = google_storage_bucket.website.name
}

# Reserving a static IP
resource "google_compute_global_address" "website" {
  name  = "website-ip"
}

# Get the managed DNS zone
data "google_dns_managed_zone""dns_zone"{
  name = "pepsi-coke"
}

# Add IP to DNS zone
resource "google_dns_record_set" "website"{
  name = data.google_dns_managed_zone.dns_zone.dns_name
  type = "A"
  ttl = 300
  managed_zone =  data.google_dns_managed_zone.dns_zone.name
  rrdatas = [google_compute_global_address.website.address]
}

# Add bucket as a CDN backend
resource "google_compute_backend_bucket" "website-backend" {
  provider    = google
  name = "website-bucket"  
  bucket_name = google_storage_bucket.website.name
  description = "contains files needed"
  enable_cdn = true
}

# Crearte URL map for Load Balancer
resource "google_compute_url_map" "website" {
  provider        = google
  name            = "website-url-map"
  default_service = google_compute_backend_bucket.website-backend.self_link
    host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.website-backend.self_link
  }
}

# Create HTTPS certificate
/*resource "google_compute_managed_ssl_certificate" "website" {
  provider = google-beta
  name     = "website-cert"
  managed {
    domains = [google_dns_record_set.website.name]
  }
}*/

# Create Load Balancer
resource "google_compute_target_http_proxy" "website" {
  provider         = google
  name             = "website-target-proxy"
  url_map          = google_compute_url_map.website.self_link
  # ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
}

# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  provider              = google
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website.address
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.website.self_link
}