# -----------------------------------------------------------------------------
# 02-iam.tf - IAM configuration for Hammerspace deployment
# -----------------------------------------------------------------------------

# Get the default compute service account to use as a fallback
data "google_compute_default_service_account" "default" {
  project = var.project_id
}

# Grant the necessary Instance Admin role to the chosen service account.
# This is needed for High Availability (HA) operations.
resource "google_project_iam_member" "instance_admin_binding" {
  # This conditional logic ensures the role is only granted if Hammerspace is being deployed in HA.
  count = contains(var.deploy_components, "hammerspace") && var.hammerspace_anvil_count > 1 ? 1 : 0

  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${local.service_account_email}"
}

# Grant the necessary Network Admin role to the chosen service account.
# This is needed for updating network interfaces (e.g., alias IPs).
resource "google_project_iam_member" "network_admin_binding" {
  # This conditional logic ensures the role is only granted if Hammerspace is being deployed.
  count = contains(var.deploy_components, "hammerspace") ? 1 : 0
  
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${local.service_account_email}"
}