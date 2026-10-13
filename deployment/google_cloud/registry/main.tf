resource "google_project_service" "artifactregistry-api" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "moon" {
  location      = var.default_region
  repository_id = "moon"
  description   = "Docker repository holding the moon related images"
  format        = "DOCKER"
}