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

variable "log_analysis_enabled" {
  type        = bool
  description = "Deploy IBM Cloud Logging agent"
  default     = true
}

variable "log_analysis_instance_name" {
  type        = string
  description = "IBM Cloud Logging instance to use. Required if Log Analysis is enabled"
  default     = null

}

variable "log_analysis_resource_group_id" {
  type        = string
  description = "Resource group the IBM Cloud Logging instance is in. Defaults to Clusters group"
  default     = null
}

variable "log_analysis_agent_version" {
  type        = string
  description = "Version of the agent to deploy. To lookup version run: `ibmcloud cr images --restrict ext/logdna-agent`. If null, the default value is used."
  # renovate: datasource=docker depName=icr.io/ext/logdna-agent versioning=regex:^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-(?<build>\d{8}).\w+?$
  default  = "3.9.0-20231211.fe6d770d2b194a59"
  nullable = false
}

variable "log_analysis_agent_tags" {
  type        = list(string)
  description = "array of tags to group the host logs pushed by the log analysis agent"
  default     = []
  nullable    = false
}

variable "log_analysis_ingestion_key" {
  type        = string
  description = "Ingestion key for the IBM Cloud Logging agent to communicate with the instance"
  sensitive   = true
  default     = null
}

variable "log_analysis_add_cluster_name" {
  type        = bool
  description = "If true, configure the log analysis agent to attach a tag containing the cluster name to all log messages."
  default     = true
}

# Log Analysis agent custom settings to setup Kubernetes metadata logs filtering
# Ref https://github.com/logdna/logdna-agent-v2/blob/3.8/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering

variable "log_analysis_agent_custom_line_inclusion" {
  description = "Log Analysis agent custom configuration for line inclusion setting LOGDNA_K8S_METADATA_LINE_INCLUSION."
  type        = string
  default     = null
}

variable "log_analysis_agent_custom_line_exclusion" {
  description = "Log Analysis agent custom configuration for line exclusion setting LOGDNA_K8S_METADATA_LINE_EXCLUSION."
  type        = string
  default     = null
}

variable "cloud_monitoring_enabled" {
  type        = bool
  description = "Deploy IBM Cloud Monitoring agent"
  default     = true
}

variable "cloud_monitoring_instance_name" {
  type        = string
  description = "The name of the IBM Cloud Monitoring instance to use. Required if Cloud Monitoring is enabled"
  default     = null
}

variable "cloud_monitoring_resource_group_id" {
  type        = string
  description = "Resource group that the IBM Cloud Monitoring is in. Defaults to Clusters group"
  default     = null
}

variable "cloud_monitoring_agent_version" {
  type        = string
  description = "IBM Cloud Monitoring Agent Version. To lookup version run: `ibmcloud cr images --restrict ext/sysdig/agent`. If null, the default value is used."
  # renovate: datasource=docker depName=icr.io/ext/sysdig/agent
  default  = "12.18.0"
  nullable = false
}

variable "cloud_monitoring_access_key" {
  type        = string
  description = "Access key used by the IBM Cloud Monitoring agent to communicate with the instance"
  sensitive   = true
  default     = null
}

variable "cloud_monitoring_metrics_filter" {
  type = list(object({
    type = string
    name = string
  }))
  description = "To filter custom metrics, specify the Cloud Monitoring metrics to include or to exclude. See  https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics."
  default     = []
  validation {
    condition     = length(var.cloud_monitoring_metrics_filter) == 0 || can(regex("^(include|exclude)$", var.cloud_monitoring_metrics_filter[0].type))
    error_message = "Invalid input for `cloud_monitoring_metrics_filter`. Valid options for 'type' are: `include` and `exclude`. If empty, no metrics are included or excluded."
  }
}

variable "cloud_monitoring_agent_tags" {
  type        = list(string)
  description = "array of tags to group the host metrics pushed by the cloud monitoring agent"
  default     = []
  nullable    = false
}

variable "cloud_monitoring_add_cluster_name" {
  type        = bool
  description = "If true, configure the cloud monitoring agent to attach a tag containing the cluster name to all metric data."
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
