terraform {
  # module uses nullable feature which is only available in versions >= 1.1.0
  required_version = ">= 1.1.0, <1.7.0"

  # Each required provider's version should be a flexible range to future proof the module's usage with upcoming minor and patch versions.
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.59.0, <2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8.0, <3.0.0"
    }
  }
}
