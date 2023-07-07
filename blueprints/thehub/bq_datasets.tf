resource "google_bigquery_dataset" "thehub" {
  project        = google_project.thehub.project_id
  dataset_id                  = "demo"
  friendly_name               = "demo"
  description                 = "This is a demo dataset"
  location                    = "US"
  labels = {
    env = var.env_abbr
  }
}
