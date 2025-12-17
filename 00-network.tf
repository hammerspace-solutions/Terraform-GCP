# Copyright (c) 2025 Hammerspace, Inc
# -----------------------------------------------------------------------------
# 00-network.tf
#
# This file creates the VPC network and subnet if they don't exist
# -----------------------------------------------------------------------------

# Create VPC network
resource "google_compute_network" "vpc_network" {
  count                   = var.create_network ? 1 : 0
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  description             = "VPC network for Hammerspace deployment"
}

# Create subnet
resource "google_compute_subnetwork" "private_subnet" {
  count                    = var.create_network ? 1 : 0
  name                     = var.subnet_name
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.vpc_network[0].id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
  description              = "Private subnet for Hammerspace deployment"
}

# Firewall rule to allow SSH
resource "google_compute_firewall" "allow_ssh" {
  count   = var.create_network && var.create_firewall_rules ? 1 : 0
  name    = "${var.network_name}-allow-ssh"
  project = var.project_id
  network = google_compute_network.vpc_network[0].name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_source_cidr_blocks
  target_tags   = var.tags
}

# Firewall rule to allow internal communication
resource "google_compute_firewall" "allow_internal" {
  count   = var.create_network && var.create_firewall_rules ? 1 : 0
  name    = "${var.network_name}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc_network[0].name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
  # No target_tags - allow internal traffic to all instances in the network
}

# Firewall rule to allow all traffic between Hammerspace instances
resource "google_compute_firewall" "allow_hammerspace_internal" {
  count   = var.create_network && var.create_firewall_rules ? 1 : 0
  name    = "${var.network_name}-allow-hammerspace"
  project = var.project_id
  network = google_compute_network.vpc_network[0].name

  allow {
    protocol = "all"
  }

  # Allow traffic from instances with hammerspace tag
  source_tags = ["hammerspace"]
  # Apply to instances with hammerspace tag
  target_tags = ["hammerspace"]
}