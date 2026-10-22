resource "google_project_service" "artifactregistry_api" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "time_sleep" "wait_45_seconds" {
  depends_on      = [google_project_service.artifactregistry_api]
  create_duration = "45s"
}

resource "google_artifact_registry_repository" "moon" {
  depends_on    = [time_sleep.wait_45_seconds]
  location      = var.default_region
  repository_id = "moon"
  description   = "Docker repository holding the moon related images"
  format        = "DOCKER"
}