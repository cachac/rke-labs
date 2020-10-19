# Data for GCP module

# GCP data
# ----------------------------------------------------------

# Use latest Ubuntu 20.04 Image
data "google_compute_image" "rke_master_image" {
  family = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}
