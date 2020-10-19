# disk
resource "google_compute_disk" "rke_node_disk" {
  name  = "master-disk"
  image = data.google_compute_image.rke_master_image.self_link
  size  = 10
  type  = "pd-standard"
  zone  = var.gcp_zone
  labels = {
    env = "dev"
  }
}

# # GCP Compute Instance for creating a single node RKE cluster and installing the Rancher server
# resource "google_compute_instance" "rke_node" {
#   # depends_on = [
#   #   google_compute_firewall.rke_fw_allowall,
#   # ]

#   name         = "${var.prefix}node01"
#   machine_type = var.machine_type
#   zone         = var.gcp_zone
#   tags         = ["type", "terraform"]
#   labels = {
#     env = "dev"
#   }

#   # if need preemptible VM (24h)
#   # preemptible = true

#   boot_disk {
#     source = google_compute_disk.rke_node_disk.id
#   }

#   network_interface {
#     network = google_compute_network.rke_network.id
#     access_config {
#       nat_ip = google_compute_address.rkeexternaladdress.address
#     }
#   }

#   metadata = {
#     ssh-keys = "cachac6:${tls_private_key.global_key.public_key_openssh}"
#     user-data = templatefile(
#       join("/", [path.module, "userdata_rancher_server.template"]),
#       {
#         docker_version = var.docker_version
#         username       = local.node_username
#       }
#     )
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "echo 'Waiting for cloud-init to complete...'",
#       "cloud-init status --wait > /dev/null",
#       "echo 'Completed cloud-init!'",
#     ]

#     connection {
#       type        = "ssh"
#       host        = self.network_interface.0.access_config.0.nat_ip
#       user        = local.node_username
#       private_key = tls_private_key.global_key.private_key_pem
#     }
#   }
# }
