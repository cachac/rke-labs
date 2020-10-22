# https://github.com/mmumshad/kubernetes-the-hard-way
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
# https://stackoverflow.com/questions/51246036/is-kubernetes-high-availability-using-kubeadm-possible-without-failover-load-bal

# individual etcd
# https://medium.com/@bambash/ha-kubernetes-cluster-via-kubeadm-b2133360b198

# stacked control plane:
# https://www.linuxtechi.com/setup-highly-available-kubernetes-cluster-kubeadm/

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
  name         = "rke-internal-address01"
  subnetwork   = google_compute_subnetwork.rke_subnet.id
  address_type = "INTERNAL"
  address      = "10.0.0.11"
  region       = var.gcp_region
}

resource "google_compute_address" "rke_external_address01" {
  name   = "rke-external-address01"
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
resource "google_compute_disk" "rke_master_disk01" {
  name  = "master-disk01"
  image = data.google_compute_image.rke_master_image.self_link
  size  = 10
  type  = "pd-standard"
  zone  = var.gcp_zone
  labels = {
    env = "dev"
  }
}

# GCP Compute Instance for creating a single node RKE cluster and installing the Rancher server
resource "google_compute_instance" "rke_master01" {
  depends_on = [google_compute_firewall.rke_fw_allowall]

  name         = "${var.prefix}master01"
  machine_type = var.machine_type
  zone         = var.gcp_zone
  tags         = ["terraform"]
  labels = {
    env = "dev"
  }

  boot_disk {
    source      = google_compute_disk.rke_master_disk01.id # "master-disk-db01"
    auto_delete = false
  }

  network_interface {
    network    = google_compute_network.rke_network.id
    subnetwork = google_compute_subnetwork.rke_subnet.id
    network_ip = google_compute_address.rke_internal_address01.address

    access_config {
      nat_ip = google_compute_address.rke_external_address01.address
      # "35.238.114.204"
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
      # using providers (uncomment below module)
      # join("/", [path.module, "userdata_rancher_server.template"]),
      # using script
      join("/", [path.module, "kubeadm_master01_script.template"]),
      {
        docker_version = var.docker_version
        username       = local.node_username
        # node_internal_ip = google_compute_address.rke_internal_address01.address
        node_public_ip = google_compute_address.rke_external_address01.address
      }
    )
  }

  # openssl config file
  # provisioner "file" {
  #   source      = "${path.module}/openssl.cnf"
  #   destination = "/home/${local.node_username}/openssl.cnf"

  #   connection {
  #     type        = "ssh"
  #     host        = self.network_interface.0.access_config.0.nat_ip
  #     user        = local.node_username
  #     private_key = tls_private_key.global_key.private_key_pem
  #   }
  # }


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

#   node_public_ip         = google_compute_instance.rke_master01.network_interface.0.access_config.0.nat_ip
#   node_internal_ip       = google_compute_instance.rke_master01.network_interface.0.network_ip
#   node_username          = local.node_username
#   ssh_private_key_pem    = tls_private_key.global_key.private_key_pem
#   rke_kubernetes_version = var.rke_kubernetes_version

#   cert_manager_version = var.cert_manager_version
#   rancher_version      = var.rancher_version

#   rancher_server_dns = join(".", ["rancher", google_compute_instance.rke_master01.network_interface.0.access_config.0.nat_ip, "xip.io"])
#   admin_password     = var.rancher_server_admin_password

#   workload_kubernetes_version = var.workload_kubernetes_version
#   workload_cluster_name       = "quickstart-gcp-custom"
# }
