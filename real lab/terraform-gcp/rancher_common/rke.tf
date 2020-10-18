provider "kubernetes" {
  config_context = "my-context"
}

resource "kubernetes_namespace" "example" {
  metadata {
    name = "my-first-namespace"
  }
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
