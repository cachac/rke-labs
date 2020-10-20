# RKE resources
# https://github.com/rancher/terraform-provider-rke
# Provision RKE cluster on provided infrastructure
resource "rke_cluster" "rancher_cluster" {
  cluster_name = "dev-server"

  nodes {
    address          = var.node_public_ip
    internal_address = var.node_internal_ip
    user             = var.node_username
    role             = ["controlplane", "etcd", "worker"]
    ssh_key          = var.ssh_private_key_pem
  }

  nodes {
    address          = "rke-worker01"
    internal_address = "10.0.0.10"
    user             = var.node_username
    role             = ["worker"]
    ssh_key          = var.ssh_private_key_pem
  }

  kubernetes_version = var.rke_kubernetes_version
}
