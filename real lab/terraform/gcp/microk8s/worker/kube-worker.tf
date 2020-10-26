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
resource "google_compute_address" "kube_internal_worker_address01" {
  name         = "kube-internal-worker-address01"
  subnetwork   = "kube-subnet"
  address_type = "INTERNAL"
  address      = "10.0.0.101"
  region       = var.gcp_region
}
resource "google_compute_address" "kube_external_worker_address01" {
  name   = "kube-external-worker-address01"
  region = var.gcp_region
}

# disk: admin by google
resource "google_compute_disk" "kube_worker_disk01" {
  name  = "worker-disk01"
  image = data.google_compute_image.kube_worker_image.self_link
  size  = 10
  type  = "pd-standard"
  zone  = var.gcp_zone
  labels = {
    env = "dev"
  }
}

# GCP Compute Instance for creating a single node KUBE cluster and installing the Rancher server
resource "google_compute_instance" "kube_worker01" {
  name         = "${var.prefix}worker01"
  machine_type = var.machine_type
  zone         = var.gcp_zone
  tags         = ["terraform"]
  labels = {
    env = "dev"
  }

  boot_disk {
    source      = google_compute_disk.kube_worker_disk01.id # "worker-disk-db01"
    auto_delete = false
  }

  network_interface {
    network    = "kube-network"
    subnetwork = "kube-subnet"
    network_ip = google_compute_address.kube_internal_worker_address01.address
    # network_ip = "10.0.0.12"

    access_config {
      nat_ip = google_compute_address.kube_external_worker_address01.address
    }
  }

  scheduling {
    # if need preemptible VM (24h)
    automatic_restart = false
    preemptible       = true
  }

  metadata = {
    ssh-keys = "${local.node_username}:${tls_private_key.global_key.public_key_openssh}",
    user-data = templatefile(
      join("/", [path.module, "microk8s.template"]),
      {
        docker_version = var.docker_version
        username       = local.node_username
        node_public_ip = google_compute_address.kube_external_worker_address01.address
				microNode   = "10.0.0.11:25000/800fe033c317fbcb4ca03f84e692643e"
      }
    )
  }

  # k8's files
  # config file
  provisioner "file" {
    source      = "../../keys/key.json"
    destination = "/home/${local.node_username}/key.json"

    connection {
      type        = "ssh"
      host        = self.network_interface.0.access_config.0.nat_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  # kubectl alias
  # provisioner "file" {
  #   source      = "../files/.kubectl_aliases"
  #   destination = "/home/${local.node_username}/.kubectl_aliases"

  #   connection {
  #     type        = "ssh"
  #     host        = self.network_interface.0.access_config.0.nat_ip
  #     user        = local.node_username
  #     private_key = tls_private_key.global_key.private_key_pem
  #   }
  # }

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
