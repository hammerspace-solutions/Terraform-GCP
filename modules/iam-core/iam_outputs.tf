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
# modules/iam-core/iam_outputs.tf
#
# This file defines all the outputs for the IAM Core module
# -----------------------------------------------------------------------------

output "service_account_email" {
  description = "Email address of the service account"
  value       = local.service_account_email
}

output "service_account_name" {
  description = "Name of the service account"
  value       = local.create_service_account ? google_service_account.main[0].name : ""
}

output "service_account_unique_id" {
  description = "Unique ID of the service account"
  value       = local.create_service_account ? google_service_account.main[0].unique_id : ""
}

output "custom_role_id" {
  description = "ID of the custom Hammerspace role"
  value       = local.create_service_account ? google_project_iam_custom_role.hammerspace[0].id : ""
}

output "assigned_roles" {
  description = "List of roles assigned to the service account"
  value       = local.all_roles
}