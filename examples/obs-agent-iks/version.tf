terraform {
  required_version = ">= 1.9.0"

  # Ensure that there is always 1 example locked into the lowest provider version of the range defined in the main
  # module's version.tf (this example), and 1 example that will always use the latest provider version (obs-agent-ocp).
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.69.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }
    # The kubernetes provider is not actually required by the module itself, just this example, so OK to use ">=" here instead of locking into a version
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
    # The time provider is not actually required by the module itself, just this example, so OK to use ">=" here instead of locking into a version
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
    # The logdna provider is not actually required by the module itself, just this example, so OK to use ">=" here instead of locking into a version
    logdna = {
      source  = "logdna/logdna"
      version = ">= 1.14.2"
    }
  }
}
