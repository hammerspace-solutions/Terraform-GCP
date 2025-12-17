# Copyright (c) 2025 Hammerspace, Inc
# -----------------------------------------------------------------------------
# 01-firewall-iap.tf
#
# Firewall rule to allow SSH via Identity-Aware Proxy (IAP)
# -----------------------------------------------------------------------------

# Allow SSH from IAP
resource "google_compute_firewall" "allow_iap_ssh" {
  count   = var.create_firewall_rules ? 1 : 0
  name    = "${var.project_name}-allow-iap-ssh"
  project = var.project_id
  network = local.network_name

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]  # SSH and RDP
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = var.tags

  description = "Allow SSH and RDP from Identity-Aware Proxy"
}