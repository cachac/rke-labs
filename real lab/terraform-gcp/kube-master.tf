# https://www.terraform.io/docs/providers/google/guides/getting_started.html
# credentials:
# install gcloud...
# gcloud auth login
# gcloud projects list
# gcloud config set project <kubernetes-292714>
# create service account:
# https://console.cloud.google.com/iam-admin/serviceaccounts?project=kubernetes-292714
# create key using gcloud:
#gcloud iam service-accounts keys create ~/key.json \
#  --iam-account terraform-bot@kubernetes-292714.iam.gserviceaccount.com
# find key in ~/key.json
# export GOOGLE_APPLICATION_CREDENTIALS=~/key.json
# add to ~/.bashrc

# terraform init
# terraform plan
# terraform apply

provider "google" {
  project = "kubernetes-292714"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-network"
  auto_create_subnetworks = "true"
}
