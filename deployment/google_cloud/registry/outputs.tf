output "registry_uri" {
  value       = google_artifact_registry_repository.moon.registry_uri
  description = "Registry URL hosting the moon images docker repository"
}

output "repository_id" {
  value       = google_artifact_registry_repository.moon.id
  description = "The complete id of the repository across all projects"
}