# https://www.terraform.io/docs/providers/google/guides/getting_started.html
# check: RKE PROVISIONER https://registry.terraform.io/providers/rancher/rke/latest/docs/resources/cluster

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

# check: provisionin Rancher cluster: https://medium.com/@chfrank_cgn/building-a-rancher-cluster-on-google-cloud-with-terraform-31f1453fbb31
# rke GCP: https://rancher.com/docs/rancher/v2.x/en/quick-start-guide/deployment/google-gcp-qs/
# GCP terraform resourses: https://www.terraform.io/docs/providers/google/r/compute_address.html

# ssh keys
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "ssh_private_key_pem" {
  filename          = "${path.module}/id_rsa"
  sensitive_content = tls_private_key.global_key.private_key_pem
  file_permission   = "0600"
}



# Networking
resource "google_compute_network" "rke_network" {
  name = "rke-network"
}

resource "google_compute_subnetwork" "rke_subnet" {
  name          = "rke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.gcp_region
  network       = google_compute_network.rke_network.id
}

resource "google_compute_address" "rke_internal_address" {
  name         = "rke-internal-address"
  subnetwork   = google_compute_subnetwork.rke_subnet.id
  address_type = "INTERNAL"
  address      = "10.0.0.2"
  region       = var.gcp_region
}

resource "google_compute_address" "rke_external_address" {
  name   = "rke-external-address"
  region = var.gcp_region
}


# ********** WARNING **********
# Firewall Rule to allow all traffic
resource "google_compute_firewall" "rke_fw_allowall" {
  name    = "${var.prefix}rke-allowall"
  network = google_compute_network.rke_network.id

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

# disk
resource "google_compute_disk" "rke_master_disk" {
  name  = "master-disk"
  image = data.google_compute_image.rke_master_image.self_link
  size  = 30
  type  = "pd-ssd"
  zone  = var.gcp_zone
  labels = {
    env = "dev"
  }
}

# GCP Compute Instance for creating a single node RKE cluster and installing the Rancher server
resource "google_compute_instance" "rke_server" {
  depends_on = [
    google_compute_firewall.rke_fw_allowall,
  ]

  name         = "${var.prefix}master"
  machine_type = var.machine_type
  zone         = var.gcp_zone
  tags         = ["type", "terraform"]
  labels = {
    env = "dev"
  }

  # if need preemptible VM (24h)
  # preemptible = true

  boot_disk {
    source = google_compute_disk.rke_master_disk.id
  }

  network_interface {
    network    = google_compute_network.rke_network.id
    subnetwork = google_compute_subnetwork.rke_subnet.id
    network_ip = google_compute_address.rke_internal_address.address

    access_config {
      nat_ip = google_compute_address.rke_external_address.address
    }
  }

  metadata = {
    ssh-keys = var.administrator_ssh
    // "cachac6:${tls_private_key.global_key.public_key_openssh}"
    user-data = templatefile(
      join("/", [path.module, "userdata_rancher_server.template"]),
      {
        docker_version   = var.docker_version
        username         = local.node_username
        node_internal_ip = google_compute_address.rke_internal_address.address
        node_public_ip   = google_compute_address.rke_external_address.address
        # ssh_public_key   = var.ssh_public_key_pem
        # ssh_private_key  = var.ssh_private_key_pem
        # kubectl_alias    = var.kubectl_alias
      }
    )
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!'",
    ]

    connection {
      type        = "ssh"
      host        = self.network_interface.0.access_config.0.nat_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  # provisioner "remote-exec" {
  #   inline = [
  #     "curl -sL https://releases.rancher.com/install-docker/${var.docker_version}.sh | sh && sudo usermod -a -G docker  ${local.node_username}",
  #     # "sudo docker run -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher:latest"
  #     "sudo wget -O /usr/local/bin/rke  https://github.com/rancher/rke/releases/download/v1.1.9/rke_linux-amd64",
  #     "sudo chmod +x /usr/local/bin/rke",
  #     "rke --version"
  #   ]

  #   connection {
  #     type        = "ssh"
  #     host        = self.network_interface.0.access_config.0.nat_ip
  #     user        = local.node_username
  #     private_key = tls_private_key.global_key.private_key_pem
  #   }
  # }
}

#
# Rancher
#
# https://www.youtube.com/watch?v=YNCq-prI8-8&feature=youtu.be

# provider "rke" {
#   log_file = "rke_debug.log"
# }

# Provision RKE cluster on provided infrastructure
# resource "rke_cluster" "rancher_cluster" {
#   cluster_name = "quickstart-rancher-server"

#   nodes {
#     address          = var.node_public_ip
#     internal_address = var.node_internal_ip
#     user             = var.node_username
#     role             = ["controlplane", "etcd", "worker"]
#     ssh_key          = var.ssh_private_key_pem
#   }

#   kubernetes_version = var.rke_kubernetes_version
# }









# simple test
# provider "google" {
#   project = "kubernetes-292714" # PROJECT_ID
#   region  = var.gcp_region
#   zone    = "us-central1-f"
# }

# resource "google_compute_instance" "vm_instance" {
#   name         = "kubemaster"
#   machine_type = "n1-standard-1"

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-9"
#     }
#   }

#   network_interface {
#     # A default network is created for all GCP projects
#     network = google_compute_network.vpc_network.self_link
#     access_config {
#     }
#   }
# }

# resource "google_compute_network" "vpc_network" {
#   name                    = "terraform-network"
#   auto_create_subnetworks = "true"
# }
