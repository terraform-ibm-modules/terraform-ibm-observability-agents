variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
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

variable "logdna_agent_custom_line_inclusion" {
  description = "LogDNA agent custom configuration for line inclusion setting LOGDNA_K8S_METADATA_LINE_INCLUSION."
  type        = string
  default     = null
}

variable "logdna_agent_custom_line_exclusion" {
  description = "LogDNA agent custom configuration for line exclusion setting LOGDNA_K8S_METADATA_LINE_EXCLUSION."
  type        = string
  default     = null
}
