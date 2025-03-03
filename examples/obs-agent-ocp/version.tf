terraform {
  required_version = ">= 1.3.0"

  # Ensure that there is always 1 example locked into the lowest provider version of the range defined in the main
  # module's version.tf (obs-agent-iks), and 1 example that will always use the latest provider version (this exammple).
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.71.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.15.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
  }
}
