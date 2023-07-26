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

