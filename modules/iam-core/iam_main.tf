# Copyright (c) 2025 Hammerspace, Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# -----------------------------------------------------------------------------
# modules/iam-core/iam_main.tf
#
# This module creates the service account and IAM bindings for all instances
# -----------------------------------------------------------------------------

locals {
  create_service_account = var.service_account_email == null
  service_account_name   = "${var.common_config.project_name}-sa"
  service_account_email  = local.create_service_account ? google_service_account.main[0].email : var.service_account_email

  # Base roles that all instances need
  base_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/compute.osLogin"
  ]

  # Combine base roles with extra roles
  all_roles = distinct(concat(local.base_roles, var.extra_roles))
}

# Create service account if one wasn't provided

resource "google_service_account" "main" {
  count = local.create_service_account ? 1 : 0

  account_id   = substr(local.service_account_name, 0, 30)
  display_name = "${var.common_config.project_name} Service Account"
  description  = "Service account for ${var.common_config.project_name} instances"
  project      = var.common_config.project_id
}

# Grant required roles to the service account

resource "google_project_iam_member" "service_account_roles" {
  for_each = local.create_service_account ? toset(local.all_roles) : toset([])

  project = var.common_config.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.main[0].email}"
}

# Allow instances to use the service account

resource "google_service_account_iam_member" "instance_user" {
  count = local.create_service_account ? 1 : 0

  service_account_id = google_service_account.main[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.main[0].email}"
}

# Create a custom role for Hammerspace-specific permissions if needed

resource "google_project_iam_custom_role" "hammerspace" {
  count = local.create_service_account ? 1 : 0

  role_id     = "${replace(var.common_config.project_name, "-", "_")}_hammerspace_role"
  title       = "${var.common_config.project_name} Hammerspace Role"
  description = "Custom role for Hammerspace operations"
  project     = var.common_config.project_id

  permissions = [
    "compute.disks.create",
    "compute.disks.delete",
    "compute.disks.get",
    "compute.disks.list",
    "compute.disks.use",
    "compute.instances.attachDisk",
    "compute.instances.detachDisk",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.setMetadata",
    "compute.zones.get",
    "compute.zones.list",
    "storage.buckets.create",
    "storage.buckets.delete",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list"
  ]
}

# Assign the custom role to the service account

resource "google_project_iam_member" "hammerspace_custom_role" {
  count = local.create_service_account ? 1 : 0

  project = var.common_config.project_id
  role    = google_project_iam_custom_role.hammerspace[0].id
  member  = "serviceAccount:${google_service_account.main[0].email}"
}