terraform {
  # module uses nullable feature which is only available in versions >= 1.1.0
  required_version = ">= 1.1.0"

  required_providers {
    # Pin to the lowest provider version of the range defined in the main module to ensure lowest version still works
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.49.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.8.0"
    }
    # The kubernetes provider is not actually required by the module itself, just this example, so OK to use ">=" here instead of locking into a version
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
    # The time provider is not actually required by the module itself, just this example, so OK to use ">=" here instead of locking into a version
    time = {
      version = ">= 0.9.1"
    }
  }
}
