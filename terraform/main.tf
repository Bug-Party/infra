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

# this is the workload identity federation pool setup that will allow our build
# pipelines to authenticate to GCP

resource "google_iam_workload_identity_pool" "pool" {
  workload_identity_pool_id = "bug-party-dev"
}

resource "google_iam_workload_identity_pool_provider" "provider" {
  workload_identity_pool_id = google_iam_workload_identity_pool.pool.id
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
