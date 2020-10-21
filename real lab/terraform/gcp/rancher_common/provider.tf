# Local provider
provider "local" {
}

# RKE provider
provider "rke" {
  log_file = "rke_debug.log"
}

# Kubernetes provider
provider "k8s" {
  host = rke_cluster.rancher_cluster.api_server_url

  client_certificate     = rke_cluster.rancher_cluster.client_cert
  client_key             = rke_cluster.rancher_cluster.client_key
  cluster_ca_certificate = rke_cluster.rancher_cluster.ca_crt

  load_config_file = false
}

# Helm provider
provider "helm" {
  kubernetes {
    host = rke_cluster.rancher_cluster.api_server_url

    client_certificate     = rke_cluster.rancher_cluster.client_cert
    client_key             = rke_cluster.rancher_cluster.client_key
    cluster_ca_certificate = rke_cluster.rancher_cluster.ca_crt

    load_config_file = false
  }
}
