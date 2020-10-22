# Required variables
# - Fill in before beginning quickstart
# ==========================================================

# Account JSON used to access GCP services
# - Specify full path and name (e.g. ~/.gcp/account.json)
gcp_account_json = "key.json"

# Project to deploy resources into
gcp_project = "kubernetes-292714"

# Password used to log in to the `admin` account on the new Rancher server
rancher_server_admin_password = "wincyre11"

# Optional variables, uncomment to customize the quickstart
# ----------------------------------------------------------

# GCP region for all resources
gcp_region = "us-central1"

# GCP zone for all resources
gcp_zone = "us-central1-a"

# Prefix for all resources created by quickstart
prefix = "kube-"

# Compute instance size of all created instances
# machine_type = "e2-standard-2"
machine_type = "e2-medium"

# Docker version installed on target hosts
# - Must be a version supported by the Rancher install scripts
# docker_version = ""

# Kubernetes version used for creating management server cluster
# - Must be supported by RKE terraform provider 1.0.1
# rke_kubernetes_version = ""

# Kubernetes version used for creating workload cluster
# - Must be supported by RKE terraform provider 1.0.1
# workload_kubernetes_version = ""

# Version of cert-manager to install, used in case of older Rancher versions
# cert_manager_version = ""

# Version of Rancher to install
# rancher_version = ""


