variable "backend_image" {
  type        = string
  description = "The full name of the backend image (registry/image:tag)"
}

variable "proxy_image" {
  type        = string
  description = "The full name of the proxy image (registry/image:tag)"
}

variable "challenger_image" {
  type        = string
  description = "The full name of the challenger image (registry/image:tag)"
}

variable "repository_id" {
  type        = string
  description = "The full ID of the image's repository (project/project-id/...)"
}

variable "moon_service_members" {
  type        = set(string)
  description = "Principals able to invoke the service"
}

data "google_project" "current_project" {}

resource "google_project_service" "cloud_run_api" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "time_sleep" "wait_42_seconds" {
  depends_on      = [google_project_service.cloud_run_api]
  create_duration = "42s"
}

module "service_account" {
  description = "Service account related to the current Cloud Run service revision"
  source      = "terraform-google-modules/service-accounts/google"
  version     = "~> 5.1"
  project_id  = var.project_id
  prefix      = "sa-cloud-run"
  names       = ["moon-${var.environment}"]
}

resource "google_artifact_registry_repository_iam_binding" "moon_repo_iam_binding" {
  depends_on = [module.service_account]
  repository = var.repository_id
  role       = "roles/artifactregistry.reader"
  members    = var.environment == "dev" ? ["serviceAccount:${module.service_account.email}"] : ["serviceAccount:service-${data.google_project.current_project.number}@serverless-robot-prod.iam.gserviceaccount.com", "serviceAccount:${module.service_account.email}"]
}

resource "google_cloud_run_service" "moon_backend" {
  depends_on = [time_sleep.wait_42_seconds, google_artifact_registry_repository_iam_binding.moon_repo_iam_binding]
  name       = "moon-backend"
  location   = var.default_region

  template {
    spec {
      service_account_name = module.service_account.email
      containers {
        name  = "backend"
        image = var.backend_image
        startup_probe {
          initial_delay_seconds = 12
          timeout_seconds       = 3
          period_seconds        = 6
          http_get {
            path = "/ready"
            port = 8000
          }
        }
      }
      containers {
        name  = "challenger"
        image = var.challenger_image
        env {
          name  = "REDIRECT_DOMAINS"
          value = "*.run.app"
        }
        startup_probe {
          initial_delay_seconds = 12
          timeout_seconds       = 3
          period_seconds        = 6
          http_get {
            path = "/ready"
            port = 8923
            http_headers {
              name  = "X-Real-IP"
              value = "127.0.0.1"
            } // workaround while waiting for a real healthcheck to be requestable, see https://github.com/TecharoHQ/anubis/issues/630
          }
        }
      }
      // Exposed container
      containers {
        name  = "proxy"
        image = var.proxy_image
        ports {
          container_port = 80
        }
        startup_probe {
          initial_delay_seconds = 12
          timeout_seconds       = 3
          period_seconds        = 6
          http_get {
            path = "/static/index.html"
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = var.environment == "dev" ? "3" : "6"
      }
    }
  }
}


data "google_iam_policy" "moon_service_auth" {
  binding {
    role    = "roles/run.invoker"
    members = var.moon_service_members
  }
}

resource "google_cloud_run_service_iam_policy" "moon_service_auth" {
  location = google_cloud_run_service.moon_backend.location
  project  = google_cloud_run_service.moon_backend.project
  service  = google_cloud_run_service.moon_backend.name

  policy_data = data.google_iam_policy.moon_service_auth.policy_data
}
