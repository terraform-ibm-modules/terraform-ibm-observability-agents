##############################################################################
# Cluster variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "The ID of the cluster you wish to deploy the agents in"
}

variable "cluster_resource_group_id" {
  type        = string
  description = "The Resource Group ID of the cluster"
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
# Log Analysis variables
##############################################################################

variable "log_analysis_enabled" {
  type        = bool
  description = "Deploy IBM Cloud Logging agent"
  default     = true
}

variable "log_analysis_agent_version" {
  type        = string
  description = "Version of the agent to deploy. To lookup version run: `ibmcloud cr images --restrict ext/logdna-agent`. If null, the default value is used."
  # renovate: datasource=docker depName=icr.io/ext/logdna-agent versioning=regex:^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-(?<build>\d{8}).\w+?$
  default  = "3.9.1-20231225.fb0af936e8df898f"
  nullable = false
}

variable "log_analysis_agent_tags" {
  type        = list(string)
  description = "List of tags to associate to all log records that the agent collects so that you can identify the agent's data quicker in the logging UI. NOTE: Use the 'log_analysis_add_cluster_name' variable to add the cluster name as a tag."
  default     = []
  nullable    = false
}

variable "log_analysis_add_cluster_name" {
  type        = bool
  description = "If true, configure the log analysis agent to attach a tag containing the cluster name to all log messages."
  default     = true
}

variable "log_analysis_ingestion_key" {
  type        = string
  description = "Ingestion key for the IBM Cloud Logging agent to communicate with the instance"
  sensitive   = true
  default     = null
}

variable "log_analysis_secret_name" {
  type        = string
  description = "The name of the secret which will store the ingestion key."
  default     = "logdna-agent"
  nullable    = false
}

variable "log_analysis_instance_region" {
  type        = string
  description = "The IBM Log Analysis instance region. Used to construct the ingestion endpoint."
  default     = null
}

variable "log_analysis_endpoint_type" {
  type        = string
  description = "Specify the IBM Log Analysis instance endpoint type (public or private) to use. Used to construct the ingestion endpoint."
  default     = "private"
  validation {
    error_message = "The specified endpoint_type can be private or public only."
    condition     = contains(["private", "public"], var.log_analysis_endpoint_type)
  }
}

variable "log_analysis_agent_custom_line_inclusion" {
  description = "Log Analysis agent custom configuration for line inclusion setting LOGDNA_K8S_METADATA_LINE_INCLUSION. See https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering for more info."
  type        = string
  default     = null
}

variable "log_analysis_agent_custom_line_exclusion" {
  description = "Log Analysis agent custom configuration for line exclusion setting LOGDNA_K8S_METADATA_LINE_EXCLUSION. See https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering for more info."
  type        = string
  default     = null
}

variable "log_analysis_agent_name" {
  description = "Log Analysis agent helm release name."
  type        = string
  default     = "logdna-agent"
  nullable    = false
}

variable "log_analysis_agent_namespace" {
  type        = string
  description = "Namespace where to deploy the Log Analysis agent. Default value is 'ibm-observe'"
  default     = "ibm-observe"
  nullable    = false
}

variable "log_analysis_agent_tolerations" {
  description = "List of tolerations to apply to Log Analysis agent."
  type = list(object({
    key               = optional(string)
    operator          = optional(string)
    value             = optional(string)
    effect            = optional(string)
    tolerationSeconds = optional(number)
  }))
  default = [{
    operator = "Exists"
  }]
}

##############################################################################
# Cloud Monitoring variables
##############################################################################

variable "cloud_monitoring_enabled" {
  type        = bool
  description = "Deploy IBM Cloud Monitoring agent"
  default     = true
}

variable "cloud_monitoring_agent_version" {
  type        = string
  description = "IBM Cloud Monitoring Agent Version. To lookup version run: `ibmcloud cr images --restrict ext/sysdig/agent`. If null, the default value is used."
  # renovate: datasource=docker depName=icr.io/ext/sysdig/agent
  default  = "12.19.0"
  nullable = false
}

variable "cloud_monitoring_access_key" {
  type        = string
  description = "Access key used by the IBM Cloud Monitoring agent to communicate with the instance"
  sensitive   = true
  default     = null
}

variable "cloud_monitoring_secret_name" {
  type        = string
  description = "The name of the secret which will store the access key."
  default     = "sysdig-agent"
  nullable    = false
}

variable "cloud_monitoring_instance_region" {
  type        = string
  description = "The IBM Cloud Monitoring instance region. Used to construct the ingestion endpoint."
  default     = null
}

variable "cloud_monitoring_endpoint_type" {
  type        = string
  description = "Specify the IBM Cloud Monitoring instance endpoint type (public or private) to use. Used to construct the ingestion endpoint."
  default     = "private"
  validation {
    error_message = "The specified endpoint_type can be private or public only."
    condition     = contains(["private", "public"], var.cloud_monitoring_endpoint_type)
  }
}

variable "cloud_monitoring_metrics_filter" {
  type = list(object({
    type = string
    name = string
  }))
  description = "To filter custom metrics, specify the Cloud Monitoring metrics to include or to exclude. See https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics."
  default     = []
  validation {
    condition     = length(var.cloud_monitoring_metrics_filter) == 0 || can(regex("^(include|exclude)$", var.cloud_monitoring_metrics_filter[0].type))
    error_message = "Invalid input for `cloud_monitoring_metrics_filter`. Valid options for 'type' are: `include` and `exclude`. If empty, no metrics are included or excluded."
  }
}

variable "cloud_monitoring_agent_tags" {
  type        = list(string)
  description = "List of tags to associate to all matrics that the agent collects. NOTE: Use the 'cloud_monitoring_add_cluster_name' variable to add the cluster name as a tag."
  default     = []
  nullable    = false
}

variable "cloud_monitoring_add_cluster_name" {
  type        = bool
  description = "If true, configure the cloud monitoring agent to attach a tag containing the cluster name to all metric data."
  default     = true
}

variable "cloud_monitoring_agent_name" {
  description = "Cloud Monitoring agent helm release name."
  type        = string
  default     = "sysdig-agent"
}

variable "cloud_monitoring_agent_namespace" {
  type        = string
  description = "Namespace where to deploy the Cloud Monitoring agent. Default value is 'ibm-observe'"
  default     = "ibm-observe"
  nullable    = false
}

variable "cloud_monitoring_agent_tolerations" {
  description = "List of tolerations to apply to Cloud Monitoring agent."
  type = list(object({
    key               = optional(string)
    operator          = optional(string)
    value             = optional(string)
    effect            = optional(string)
    tolerationSeconds = optional(number)
  }))
  default = [{
    operator = "Exists"
    },
    {
      operator : "Exists"
      effect : "NoSchedule"
      key : "node-role.kubernetes.io/master"
  }]
}
