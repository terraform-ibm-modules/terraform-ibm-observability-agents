##############################################################################
# Input variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API Key"
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Region"
}

variable "prefix" {
  type        = string
  description = "The prefix to add to all resources."
}

variable "resource_group" {
  type        = string
  description = "The name of an existing resource group to provision resources in. If not specified, a new resource group is created with the `prefix` variable."
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "The tags to add to the created resources."
  default     = []
}
