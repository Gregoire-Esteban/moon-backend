## This file contains both terraform initalisation elements and provider configuration

variable "project_id" {
  description = "Id of targeted project"
  type        = string
}

variable "default_region" {
  description = "Default region"
  type        = string
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.default_region
}