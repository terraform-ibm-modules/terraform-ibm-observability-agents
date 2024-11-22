provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
}

provider "kubernetes" {
  host  = var.host
  token = var.token
}

provider "helm" {
  kubernetes {
    host  = var.host
    token = var.token
  }
  # IBM Cloud credentials are required to authenticate to the helm repo
  registry {
    url      = var.registry_url
    username = "iamapikey"
    password = var.ibmcloud_api_key
  }
}
