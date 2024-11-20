provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
}

provider "kubernetes" {
  host  = data.ibm_container_cluster_config.cluster_config.host
  token = data.ibm_container_cluster_config.cluster_config.token
}

provider "helm" {
  kubernetes {
    host  = data.ibm_container_cluster_config.cluster_config.host
    token = data.ibm_container_cluster_config.cluster_config.token
  }
  # IBM Cloud credentials are required to authenticate to the helm repo
  registry {
    url      = "oci://icr.io/ibm/observe/logs-agent-helm"
    username = "iamapikey"
    password = var.ibmcloud_api_key
  }
}

# Retrieve information about an existing VPC cluster
data "ibm_container_vpc_cluster" "cluster" {
  count             = var.is_vpc_cluster ? 1 : 0
  name              = var.cluster_id
  wait_till         = var.wait_till
  wait_till_timeout = var.wait_till_timeout
}

# Retrieve information about an existing Classic cluster
data "ibm_container_cluster" "cluster" {
  count             = var.is_vpc_cluster ? 0 : 1
  name              = var.cluster_id
  wait_till         = var.wait_till
  wait_till_timeout = var.wait_till_timeout
}
