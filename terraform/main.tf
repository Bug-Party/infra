provider "google" {
  project = "bug-party-dev"
  region  = "us-east1"
}

terraform {
 backend "gcs" {
   bucket  = "bug-party-tfstate"
   prefix  = "terraform/state"
 }
}

# this service account our build pipelines will use to push docker images to
# our artifact registry
resource "google_service_account" "build_pipeline" {
  account_id = "build-pipeline"
}

resource "google_project_iam_member" "build_pipeline_artifact_writer" {
  project = "bug-party-dev"
  role = "roles/artifactregistry.writer"
  member = "serviceAccount:${google_service_account.build_pipeline.email}"
}

resource "google_project_iam_member" "build_pipeline_artifact_reader" {
  project = "bug-party-dev"
  role = "roles/artifactregistry.reader"
  member = "serviceAccount:${google_service_account.build_pipeline.email}"
}

# this is the workload identity federation pool setup that will allow our build
# pipelines to authenticate to GCP

resource "google_iam_workload_identity_pool" "pool" {
  workload_identity_pool_id = "bug-party-dev"
}

resource "google_iam_workload_identity_pool_provider" "provider" {
  workload_identity_pool_id = google_iam_workload_identity_pool.pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "bug-party-dev"
    oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  attribute_mapping = {
    "attribute.aud" = "assertion.aud"
    "attribute.actor" = "assertion.actor"
    "google.subject" = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }
}

resource "google_service_account_iam_member" "workload_identity_pool_binding" {
  service_account_id = google_service_account.build_pipeline.name
  role = "roles/iam.workloadIdentityUser"
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool.name}/attribute.repository/Bug-Party/game-server"
}

resource "google_artifact_registry_repository" "registry" {
  location      = "us-east1"
  repository_id = "bug-party-dev"
  format        = "DOCKER"
}

output workload_identity_pool_provider {
  value = google_iam_workload_identity_pool_provider.provider.name
}

output service_account_email {
  value = google_service_account.build_pipeline.email
}

