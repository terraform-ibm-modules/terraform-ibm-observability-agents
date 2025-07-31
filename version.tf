terraform {
  required_version = ">= 1.9.0"

  # Each required provider's version should be a flexible range to future proof the module's usage with upcoming minor and patch versions.
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.70.0, <2.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0, <4.0.0"
    }
  }
}
