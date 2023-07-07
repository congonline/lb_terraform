resource "google_storage_bucket" "thehub" {
  project        = google_project.thehub.project_id
  name          = "lb-${var.env_abbr}-thehub-${local.random_id}"
  location      = var.default_region
  force_destroy = true

  public_access_prevention = "enforced"
  retention_policy {
    retention_period  = 120
  }
}
