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

variable "prefix" {
  type        = string
  description = "A prefix for the name of all resources that are created by this example"
  default     = "test-obs-agents"
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
  default     = "us-east"
}

variable "atracker_trusted_profile" {
  type        = string
  description = "The IBM Cloud trusted profile ID. Used only when `atracker_iam_mode` is set to `TrustedProfile`."
  default     = null
}

variable "service_names" {
  type        = list(string)
  description = "Your IBM Cloud service names that will be included as part of the `logSourceCRN` value in the logs."
  default = [ "goldeneye" ]
}