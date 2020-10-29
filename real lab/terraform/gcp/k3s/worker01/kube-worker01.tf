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
resource "google_compute_address" "k3s_internal_address_worker01" {
  name         = "k3s-internal-address-worker01"
  subnetwork   = "k3s-subnet"
  address_type = "INTERNAL"
  address      = "10.0.0.101"
  region       = var.gcp_region
}

resource "google_compute_address" "k3s_external_address_worker01" {
  name   = "k3s-external-address-worker01"
  region = var.gcp_region
}

# disk: admin by google
resource "google_compute_disk" "k3s_worker_disk01" {
  name  = "k3s-worker-disk01"
  image = data.google_compute_image.rke_master_image.self_link
  size  = 10
  type  = "pd-standard"
  zone  = var.gcp_zone
  labels = {
    env = "dev"
  }
}

# GCP Compute Instance for creating a single node k3s cluster and installing the Rancher server
resource "google_compute_instance" "k3s_worker01" {
  name         = "${var.prefix}worker01"
  machine_type = var.machine_type
  zone         = var.gcp_zone
  tags         = ["terraform"]
  labels = {
    env = "dev"
  }

  boot_disk {
    source      = google_compute_disk.k3s_worker_disk01.id # "worker-disk-db01"
    auto_delete = false
  }

  network_interface {
    network    = "k3s-network"
    subnetwork = "k3s-subnet"
    network_ip = google_compute_address.k3s_internal_address_worker01.address

    access_config {
      nat_ip = google_compute_address.k3s_external_address_worker01.address
      # "35.238.114.204"
    }
  }

  # scheduling {
  #   # if need preemptible VM (24h)
  #   automatic_restart = false
  #   preemptible       = true
  # }

  metadata = {
    ssh-keys = "${local.node_username}:${tls_private_key.global_key.public_key_openssh}",
    user-data = templatefile(
      # using providers (uncomment below module)
      # join("/", [path.module, "userdata_rancher_server.template"]),
      # using script
      join("/", [path.module, "k3s_worker01_script.template"]),
      {
        docker_version = var.docker_version
        username       = local.node_username
        # node_internal_ip = google_compute_address.k3s_internal_address01.ad_workerdress
        node_public_ip = google_compute_address.k3s_external_address_worker01.address
      }
    )
  }

	# k8's files
  provisioner "file" {
    source      = "../../../../app/deployment.yaml"
    destination = "/home/${local.node_username}/deployment.yaml"

    connection {
      type        = "ssh"
      host        = self.network_interface.0.access_config.0.nat_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  provisioner "file" {
    source      = "../../../../app/clusterIP.yaml"
    destination = "/home/${local.node_username}/clusterIP.yaml"

    connection {
      type        = "ssh"
      host        = self.network_interface.0.access_config.0.nat_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  provisioner "file" {
    source      = "../../../../app/ingress.yaml"
    destination = "/home/${local.node_username}/ingress.yaml"

    connection {
      type        = "ssh"
      host        = self.network_interface.0.access_config.0.nat_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  provisioner "file" {
    source      = "../../../../app/production_clusterIssuer.yaml"
    destination = "/home/${local.node_username}/production_clusterIssuer.yaml"

    connection {
      type        = "ssh"
      host        = self.network_interface.0.access_config.0.nat_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  provisioner "file" {
    source      = "../../../../app/staging_clusterIssuer.yaml"
    destination = "/home/${local.node_username}/staging_clusterIssuer.yaml"

    connection {
      type        = "ssh"
      host        = self.network_interface.0.access_config.0.nat_ip
      user        = local.node_username
      private_key = tls_private_key.global_key.private_key_pem
    }
  }

  # kubectl alias
  provisioner "file" {
    source      = "${path.module}/.kubectl_aliases"
    destination = "/home/${local.node_username}/.kubectl_aliases"

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

# using providers
# module "rancher_common" {
#   source = "../rancher_common"

#   node_public_ip         = google_compute_instance.k3s_worker01.network_interface.0.access_config.0.nat_ip
#   node_internal_ip       = google_compute_instance.k3s_worker01.network_interface.0.network_ip
#   node_username          = local.node_username
#   ssh_private_key_pem    = tls_private_key.global_key.private_key_pem
#   k3s_kubernetes_version = var.k3s_kubernetes_version

#   cert_manager_version = var.cert_manager_version
#   rancher_version      = var.rancher_version

#   rancher_server_dns = join(".", ["rancher", google_compute_instance.k3s_worker01.network_interface.0.access_config.0.nat_ip, "xip.io"])
#   admin_password     = var.rancher_server_admin_password

#   workload_kubernetes_version = var.workload_kubernetes_version
#   workload_cluster_name       = "quickstart-gcp-custom"
# }
