terraform {
  # module uses nullable feature which is only available in versions >= 1.1.0
  required_version = ">= 1.1.0"
  required_providers {
    ibm = {
      # Use "greater than or equal to" range in modules
      source  = "ibm-cloud/ibm"
      version = ">= 1.49.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0"
    }
  }
}
