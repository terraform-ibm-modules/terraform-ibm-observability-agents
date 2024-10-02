variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "A prefix for the name of all resources that are created by this example"
  default     = "obs-agent-iks"
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example. If not specified, a new resource group is created."
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "A list of tags to add to the resources that are created."
  default     = []
}

variable "region" {
  type        = string
  description = "The region where the resources are created."
  default     = "au-syd"
}

variable "is_vpc_cluster" {
  type        = bool
  description = "Specify true if the target cluster for the observability agents is a VPC cluster, false if it is classic cluster."
  default     = true
}

variable "datacenter" {
  type        = string
  description = "If creating a classic cluster, the data center where the cluster is created"
  default     = "syd01"
}
