variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

variable "is_openshift" {
  type        = bool
  description = "Defines whether this is an OpenShift or Kubernetes cluster"
  default     = true
}

variable "is_vpc_cluster" {
  type        = bool
  description = "Specify true if the target cluster for the observability agents is a VPC cluster, false if it is classic cluster."
  default     = true
}

variable "prefix" {
  type        = string
  description = "Prefix for name of all resource created by this example"
  default     = "test-obs-agents"
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "region" {
  type        = string
  description = "Region where resources are created"
  default     = "ca-tor"
}

variable "datacenter" {
  type        = string
  description = "If creating a classic cluster, the data center where the cluster is created"
  default     = "syd01"
}
