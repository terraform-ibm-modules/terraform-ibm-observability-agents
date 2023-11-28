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
  default  = "3.9.0-20231127.1da2b0706ea2d823"
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

# LogDNA agent custom settings to setup Kubernetes metadata logs filtering
# Ref https://github.com/logdna/logdna-agent-v2/blob/3.8/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering

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
  default  = "12.18.0"
  nullable = false
}

variable "sysdig_access_key" {
  type        = string
  description = "Access key used by the IBM Cloud Monitoring agent to communicate with the instance"
  sensitive   = true
  default     = null
}

variable "sysdig_metrics_filter" {
  type = list(object({
    type = string
    name = string
  }))
  description = "To filter custom metrics, specify the Sysdig metrics to include or to exclude. See  https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics."
  default     = []
  validation {
    condition     = length(var.sysdig_metrics_filter) == 0 || can(regex("^(include|exclude)$", var.sysdig_metrics_filter[0].type))
    error_message = "Invalid input for `sysdig_metrics_filter`. Valid options for 'type' are: `include` and `exclude`. If empty, no metrics are included or excluded."
  }
}

variable "sysdig_agent_tags" {
  type        = list(string)
  description = "array of tags to group the host metrics pushed by the sysdig agent"
  default     = []
  nullable    = false
}

variable "sysdig_add_cluster_name" {
  type        = bool
  description = "If true, configure the sysdig agent to attach a tag containing the cluster name to all metric data."
  default     = true
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false # use default if null is passed in
  validation {
    error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}

##############################################################################
