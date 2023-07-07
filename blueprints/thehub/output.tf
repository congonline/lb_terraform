output "project_id" {
  value = google_project.thehub.project_id
}

output "project_number" {
  value = google_project.thehub.number
}

output "thehubstorage" {
  value = google_storage_bucket.thehub.name
}
