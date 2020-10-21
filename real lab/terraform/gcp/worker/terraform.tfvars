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
gcp_zone = "us-central1-c"

# Prefix for all resources created by quickstart
prefix = "rke-"

# Compute instance size of all created instances
# machine_type = "n1-standard-1"
# machine_type = "e2-medium"
machine_type = "e2-small"

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

administrator_ssh = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDRhsGbSwowiQFH7ZE5lWo+wn4nLyCQ4eYfSRKsfsELQhT1c8QuJBTv5dHIOKBjEB+jmENNQ2U8ossgiiAQqqOr2wS06Fj0zTdJUzmwMUByEVP9QEasPN9QvbjzeD++kHfq04pFxew2X1NUh+XYMH+KXIEbcnQDgZ1RSRY4zPDxbT914Xw+BH3yCf26Vy7VHQZ1JWTvIz9eq1viQ03tqVcicAwVOP4GUbEb3MVE0/0UVKTXGSWhSSNGvhQWP2KVmxQqqYfP011OUqyVa1CKMryEMiZj2W9/1uLrZUFWKuo5vmd1264db+vRGCuqdrQcbPYyNYFa91r7Ke9ceCaE5+JWkWuLmDBSrJJa16cQC6Kx1r6Epx7EM7ie2TDkpow3dQ2o40VlNFzAQ5QqXmQr0FNRNSHZDfdRmhvL56YTSm2JMG5FLvIX3g98WjtyShsdxp8/2ED+a6zM2bZLqDBoG3EMoIbWXZrO/VRXaPw+O6hs+DvqsFjr++tuhVaBSKDq5U0= cachac6@localhome"
# administrator_ssh_keypath = "/home/cachac6/.ssh/id_rsa"

