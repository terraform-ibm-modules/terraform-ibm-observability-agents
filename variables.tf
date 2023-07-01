##############################################################################
# Input Variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "Cluster id to add to agents to"
}

variable "cluster_resource_group_id" {
  type        = string
  description = "Resource group of the cluster"
}

variable "logdna_enabled" {
  type        = bool
  description = "Deploy IBM Cloud Logging agent"
  default     = true
}

variable "logdna_instance_name" {
  type        = string
  description = "IBM Cloud Logging instance to use. Required if LogDNA is enabled"
  default     = null

}

variable "logdna_resource_group_id" {
  type        = string
  description = "Resource group the IBM Cloud Logging instance is in. Defaults to Clusters group"
  default     = null
}

variable "logdna_agent_version" {
  type        = string
  description = "Version of the agent to deploy. To lookup version run: `ibmcloud cr images --restrict ext/logdna-agent`. If null, the default value is used."
  # renovate: datasource=docker depName=icr.io/ext/logdna-agent versioning=regex:^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-(?<build>\d{8}).\w+?$
  default  = "3.8.5-20230622.97492a8c2f1d8fe7"
  nullable = false
}

variable "logdna_agent_tags" {
  type        = list(string)
  description = "array of tags to group the host logs pushed by the logdna agent"
  default     = []
  nullable    = false
}

variable "logdna_ingestion_key" {
  type        = string
  description = "Ingestion key for the IBM Cloud Logging agent to communicate with the instance"
  sensitive   = true
  default     = null
}

variable "logdna_add_cluster_name" {
  type        = bool
  description = "If true, configure the logdna agent to attach a tag containing the cluster name to all log messages."
  default     = true
}

variable "sysdig_enabled" {
  type        = bool
  description = "Deploy IBM Cloud Monitoring agent"
  default     = true
}

variable "sysdig_instance_name" {
  type        = string
  description = "The name of the IBM Cloud Monitoring instance to use. Required if Sysdig is enabled"
  default     = null
}

variable "sysdig_resource_group_id" {
  type        = string
  description = "Resource group that the IBM Cloud Monitoring is in. Defaults to Clusters group"
  default     = null
}

variable "sysdig_agent_version" {
  type        = string
  description = "IBM Cloud Monitoring Agent Version. To lookup version run: `ibmcloud cr images --restrict ext/sysdig/agent`. If null, the default value is used."
  # renovate: datasource=docker depName=icr.io/ext/sysdig/agent
  default  = "12.15.0"
  nullable = false
}

variable "sysdig_access_key" {
  type        = string
  description = "Access key used by the IBM Cloud Monitoring agent to communicate with the instance"
  sensitive   = true
  default     = null
}

##############################################################################
