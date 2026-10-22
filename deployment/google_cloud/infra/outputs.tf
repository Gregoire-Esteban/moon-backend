output "service_url" {
  value       = google_cloud_run_service.moon_backend.status[0].url
  description = "Deployed moon service url"
}