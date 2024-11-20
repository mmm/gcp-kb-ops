#
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

data "google_compute_network" "tutorial" { name = var.network }
data "google_compute_subnetwork" "tutorial" {
  name = var.subnet
  region = var.region
}

resource "google_container_cluster" "primary" {
  name     = var.k8s-cluster-name
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network = data.google_compute_network.tutorial.name
  subnetwork = data.google_compute_subnetwork.tutorial.name

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes = true
    master_ipv4_cidr_block = "10.13.0.0/28"
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block = "10.11.0.0/21"
    services_ipv4_cidr_block = "10.12.0.0/21"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "10.2.1.0/24"
      display_name = "tutorial_block"
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = google_container_cluster.primary.name
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  network_config {
    enable_private_nodes = true
  }

  node_config {
    preemptible  = false
    machine_type = "e2-medium"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    #service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable_legacy_endpoints = true
    }
  }
}
