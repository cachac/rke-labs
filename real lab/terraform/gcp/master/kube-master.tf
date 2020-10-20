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
# terraform apply -auto-approve
# terraform destroy -target google_compute_instance.rke_server -auto-approve

# check: provisionin Rancher cluster: https://medium.com/@chfrank_cgn/building-a-rancher-cluster-on-google-cloud-with-terraform-31f1453fbb31
# rke GCP: https://rancher.com/docs/rancher/v2.x/en/quick-start-guide/deployment/google-gcp-qs/
# GCP terraform resourses: https://www.terraform.io/docs/providers/google/r/compute_address.html

# ssh keys
resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "local_file" "ssh_private_key_pem" {
  # filename          = "${path.module}/id_rsa"
  filename          = "../../keys/id_rsa"
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

resource "google_compute_address" "rke_internal_address01" {
  name         = "rke-internal-address"
  subnetwork   = google_compute_subnetwork.rke_subnet.id
  address_type = "INTERNAL"
  address      = "10.0.0.2"
  region       = var.gcp_region
}

resource "google_compute_address" "rke_external_address01" {
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

# disk: admin by google
resource "google_compute_disk" "rke_master_disk" {
  name  = "master-disk"
  image = data.google_compute_image.rke_master_image.self_link
  size  = 10
  type  = "pd-standard"
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

  boot_disk {
    source      = google_compute_disk.rke_master_disk.id # "master-disk-db01"
    auto_delete = false
  }

  network_interface {
    network    = google_compute_network.rke_network.id
    subnetwork = google_compute_subnetwork.rke_subnet.id
    network_ip = google_compute_address.rke_internal_address01.address

    access_config {
      nat_ip = google_compute_address.rke_external_address01.address
    }
  }

  scheduling {
    # if need preemptible VM (24h)
    automatic_restart = false
    preemptible       = true
  }

  metadata = {
    # ssh-keys = var.administrator_ssh
    ssh-keys = "${local.node_username}:${tls_private_key.global_key.public_key_openssh}",
    user-data = templatefile(
      join("/", [path.module, "userdata_rancher_server.template"]),
      {
        docker_version   = var.docker_version
        username         = local.node_username
        node_internal_ip = google_compute_address.rke_internal_address01.address
        node_public_ip   = google_compute_address.rke_external_address01.address
        # ssh_public_key   = var.ssh_public_key_pem
        # ssh_private_key  = var.ssh_private_key_pem
        # kubectl_alias    = var.kubectl_alias
      }
    )
  }

  provisioner "file" {
    source      = "${path.module}/.kubectl_aliases"
    destination = "/home/cachac6/.kubectl_aliases"

    connection {
      type        = "ssh"
      host        = self.network_interface.0.access_config.0.nat_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait > /dev/null",
      "echo 'Completed cloud-init!!'",
    ]

    connection {
      type        = "ssh"
      host        = self.network_interface.0.access_config.0.nat_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }
}

module "rancher_common" {
  source = "../rancher_common"

  node_public_ip         = google_compute_instance.rke_server.network_interface.0.access_config.0.nat_ip
  node_internal_ip       = google_compute_instance.rke_server.network_interface.0.network_ip
  node_username          = local.node_username
  ssh_private_key_pem    = tls_private_key.global_key.private_key_pem
  rke_kubernetes_version = var.rke_kubernetes_version

  cert_manager_version = var.cert_manager_version
  rancher_version      = var.rancher_version

  rancher_server_dns = join(".", ["rancher", google_compute_instance.rke_server.network_interface.0.access_config.0.nat_ip, "xip.io"])
  admin_password     = var.rancher_server_admin_password

  workload_kubernetes_version = var.workload_kubernetes_version
  workload_cluster_name       = "quickstart-gcp-custom"
}
