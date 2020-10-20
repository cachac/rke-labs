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
resource "google_compute_address" "rke_worker_external_address01" {
  name   = "rke-worker-external-address01"
  region = var.gcp_region
}

# disk: admin by google
# resource "google_compute_disk" "rke_worker_disk01" {
#   name  = "worker-disk01"
#   image = data.google_compute_image.rke_worker_image.self_link
#   size  = 10
#   type  = "pd-standard"
#   zone  = var.gcp_zone
#   labels = {
#     env = "dev"
#   }
# }

# GCP Compute Instance for creating a single node RKE cluster and installing the Rancher server
resource "google_compute_instance" "rke_worker01" {
  name         = "${var.prefix}worker01"
  machine_type = var.machine_type
  zone         = var.gcp_zone
  tags         = ["type", "terraform"]
  labels = {
    env = "dev"
  }

  boot_disk {
    source      = "worker-disk-db01" # google_compute_disk.rke_worker_disk01.id
    auto_delete = false
  }


  network_interface {
    network    = "rke-network"
    subnetwork = "rke-subnet"
    network_ip = "10.0.0.10"

    access_config {
      nat_ip = google_compute_address.rke_worker_external_address01.address
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
      join("/", [path.module, "userdata_worker.template"]),
      {
        docker_version = var.docker_version
        username       = local.node_username
      }
    )
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


