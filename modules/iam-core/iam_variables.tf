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
# modules/iam-core/iam_variables.tf
#
# This file defines all the input variables for the IAM Core module
# -----------------------------------------------------------------------------

variable "common_config" {
  description = "A map containing common configuration values like project, region, network, etc."
  type = object({
    project_id            = string
    region                = string
    zone                  = string
    network_name          = string
    subnet_name           = string
    subnet_self_link      = string
    tags                  = list(string)
    labels                = map(string)
    project_name          = string
    ssh_keys_dir          = string
    allow_root            = bool
    placement_policy_name = string
    allowed_source_cidr_blocks = list(string)
  })
}

# Optional: attach additional roles to the service account

variable "extra_roles" {
  description = "Additional GCP roles to grant to the service account"
  type        = list(string)
  default     = []
}

# If this is set (non-null), this module must NOT create a new service account

variable "service_account_email" {
  description = "If you have an existing service account email, then this module will not create a new one"
  type        = string
  default     = null
}