# Kubernetes provider
provider "k8s" {
  host = "10.0.0.2"
	# rke_cluster.rancher_cluster.api_server_url

  client_certificate     = rke_cluster.rancher_cluster.client_cert
  client_key             = rke_cluster.rancher_cluster.client_key
  cluster_ca_certificate = rke_cluster.rancher_cluster.ca_crt

  load_config_file = false
}

# Configure RKE provider
provider "rke" {
  log_file = "rke_debug.log"
}
# Create a new RKE cluster using arguments
resource "rke_cluster" "foo2" {
  nodes {
    address = "10.0.0.2"
    user    = "cachac6"
    role    = ["controlplane", "worker", "etcd"]
    ssh_key = file("~/.ssh/id_rsa")
  }
  upgrade_strategy {
      drain = true
      max_unavailable_worker = "20%"
  }
}
