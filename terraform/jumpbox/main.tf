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

locals {
  jumpbox_count          = 1
  master_os_image       = "debian-cloud/debian-12" #"ubuntu-os-cloud/ubuntu-2204-lts"
  default_instance_type = "n2-standard-4"
}

data "google_compute_network" "tutorial" { name = var.network }
data "google_compute_subnetwork" "tutorial" {
  name = var.subnet
  region = join("-", slice(split("-", var.zone), 0, 2))
}

resource "google_compute_instance" "jumpbox" {
  count        = local.jumpbox_count
  name         = "jumpbox-${count.index}"
  machine_type = local.default_instance_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = local.master_os_image
      size = 300
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  network_interface {
    network = data.google_compute_network.tutorial.name
    subnetwork = data.google_compute_subnetwork.tutorial.name
    # access_config {} # Ephemeral IP
  }

  metadata_startup_script = templatefile("provision.sh.tmpl", { home_ip = "", tools_ip = "" })

  service_account {
    # scopes = ["userinfo-email", "compute-ro", "storage-full"]
    scopes = ["cloud-platform"] # too permissive for production
  }
}
