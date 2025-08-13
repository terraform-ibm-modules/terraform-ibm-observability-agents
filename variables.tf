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

variable "is_vpc_cluster" {
  description = "Specify true if the target cluster for the observability agents is a VPC cluster, false if it is a classic cluster."
  type        = bool
  default     = true
}

variable "wait_till" {
  description = "To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal`"
  type        = string
  default     = "Normal"

  validation {
    error_message = "`wait_till` value must be one of `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` or `Normal`."
    condition = contains([
      "MasterNodeReady",
      "OneWorkerNodeReady",
      "IngressReady",
      "Normal"
    ], var.wait_till)
  }
}

variable "wait_till_timeout" {
  description = "Timeout for wait_till in minutes."
  type        = number
  default     = 90
}

##############################################################################
# Cloud Monitoring variables
##############################################################################

variable "cloud_monitoring_enabled" {
  type        = bool
  description = "Deploy IBM Cloud Monitoring agent"
  default     = true

  validation {
    condition = !var.cloud_monitoring_enabled || (
      var.cloud_monitoring_access_key != null &&
      var.cloud_monitoring_instance_region != null
    )
    error_message = "When cloud_monitoring_enabled is true, both cloud_monitoring_access_key and cloud_monitoring_instance_region must be provided."
  }
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
    include = optional(string)
    exclude = optional(string)
  }))
  description = "To filter custom metrics you can specify which metrics to include and exclude. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics"
  default     = []
  validation {
    condition = alltrue([
      for item in var.cloud_monitoring_metrics_filter : (
        (
          (!(try(item.include, null) != null && try(item.exclude, null) != null)) &&
          ((try(item.include, null) != null && try(item.include, "") != "") || (try(item.exclude, null) != null && try(item.exclude, "") != ""))
        )
      )
    ])
    error_message = "Each cloud_monitoring_metrics_filter item must specify exactly one of 'include' or 'exclude' with a non-empty value. Empty lists [] are allowed."
  }
}

variable "cloud_monitoring_container_filter" {
  type = list(object({
    type      = string
    parameter = string
    name      = string
  }))
  description = "To filter custom containers, specify which containers to include or exclude from metrics collection for the cloud monitoring agent. See https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_filter_data."
  default     = []
  validation {
    condition     = length(var.cloud_monitoring_container_filter) == 0 || can(regex("^(include|exclude)$", var.cloud_monitoring_container_filter[0].type))
    error_message = "Invalid input for `cloud_monitoring_container_filter`. Valid options for 'type' are: `include` and `exclude`. If empty, no containers are included or excluded."
  }
}

variable "cloud_monitoring_agent_tags" {
  type        = list(string)
  description = "List of tags to associate to all matrics that the agent collects. NOTE: Use the 'cloud_monitoring_add_cluster_name' variable to add the cluster name as a tag."
  default     = []
  nullable    = false

  validation {
    condition     = alltrue([for tags in var.cloud_monitoring_agent_tags : !can(regex("\\s", tags))])
    error_message = "The cloud monitoring agent tags must not contain any spaces."
  }
}

variable "cloud_monitoring_add_cluster_name" {
  type        = bool
  description = "If true, configure the cloud monitoring agent to attach a tag containing the cluster name to all metric data."
  default     = true
}

variable "cloud_monitoring_agent_name" {
  description = "Cloud Monitoring agent name. Used for naming all kubernetes and helm resources on the cluster."
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

variable "enable_universal_ebpf" {
  type        = bool
  description = "Deploy monitoring agent with universal extended Berkeley Packet Filter (eBPF) enabled. It requires kernel version 5.8+. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/blob/main/solutions/fully-configurable/DA-docs.md#when-to-enable-enable_universal_ebpf)"
  default     = true
}

##############################################################################
# Logs Agents variables
##############################################################################

variable "logs_agent_enabled" {
  type        = bool
  description = "Whether to deploy the Logs agent."
  default     = true
}

variable "logs_agent_name" {
  description = "The name of the Logs agent. The name is used in all Kubernetes and Helm resources in the cluster."
  type        = string
  default     = "logs-agent"
  nullable    = false
}

variable "logs_agent_namespace" {
  type        = string
  description = "The namespace where the Logs agent is deployed. The default value is `ibm-observe`."
  default     = "ibm-observe"
  nullable    = false
}

variable "logs_agent_trusted_profile" {
  type        = string
  description = "The IBM Cloud trusted profile ID. Used only when `logs_agent_iam_mode` is set to `TrustedProfile`. The trusted profile must have an IBM Cloud Logs `Sender` role."
  default     = null

  validation {
    condition = (
      var.logs_agent_enabled == false ||
      var.logs_agent_iam_mode != "TrustedProfile" ||
      (var.logs_agent_trusted_profile != null && var.logs_agent_trusted_profile != "")
    )
    error_message = "When passing 'TrustedProfile' value for 'logs_agent_iam_mode' you cannot set 'logs_agent_trusted_profile' as null or empty string."
  }
}

variable "logs_agent_iam_api_key" {
  type        = string
  description = "The IBM Cloud API key for the Logs agent to authenticate and communicate with the IBM Cloud Logs. It is required if `logs_agent_iam_mode` is set to `IAMAPIKey`."
  sensitive   = true
  default     = null

  validation {
    condition = (
      var.logs_agent_enabled == false ||
      var.logs_agent_iam_mode != "IAMAPIKey" ||
      (var.logs_agent_iam_api_key != null && var.logs_agent_iam_api_key != "")
    )
    error_message = "When passing 'IAMAPIKey' value for 'logs_agent_iam_mode', you cannot set 'logs_agent_iam_api_key' as null or empty string."
  }
}

variable "logs_agent_tolerations" {
  description = "List of tolerations to apply to Logs agent. The default value means a pod will run on every node."
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

variable "logs_agent_additional_log_source_paths" {
  type        = list(string)
  description = "The list of additional log sources. By default, the Logs agent collects logs from a single source at `/var/log/containers/*.log`."
  default     = []
  nullable    = false
}

variable "logs_agent_exclude_log_source_paths" {
  type        = list(string)
  description = "The list of log sources to exclude. Specify the paths that the Logs agent ignores."
  default     = []
  nullable    = false
}

variable "logs_agent_selected_log_source_paths" {
  type        = list(string)
  description = "The list of specific log sources paths. Logs will only be collected from the specified log source paths. If no paths are specified, it will send logs from `/var/log/containers`."
  default     = []
  nullable    = false
}

variable "logs_agent_log_source_namespaces" {
  type        = list(string)
  description = "The list of namespaces from which logs should be forwarded by agent. If namespaces are not listed, logs from all namespaces will be sent."
  default     = []
  nullable    = false
}

variable "logs_agent_iam_mode" {
  type        = string
  default     = "TrustedProfile"
  description = "IAM authentication mode: `TrustedProfile` or `IAMAPIKey`."
}

variable "logs_agent_iam_environment" {
  type        = string
  default     = "PrivateProduction"
  description = "IAM authentication Environment: `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`. `Production` specifies the public endpoint & `PrivateProduction` specifies the private endpoint."
}

variable "logs_agent_additional_metadata" {
  description = "The list of additional metadata fields to add to the routed logs."
  type = list(object({
    key   = optional(string)
    value = optional(string)
  }))
  default = []
}

variable "logs_agent_enable_scc" {
  description = "Whether to enable creation of Security Context Constraints in Openshift. When installing on an OpenShift cluster, this setting is mandatory to configure permissions for pods within your cluster."
  type        = bool
  default     = true
}

variable "cloud_logs_ingress_endpoint" {
  description = "The host for IBM Cloud Logs ingestion. Ensure you use the ingress endpoint. See https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-endpoints_ingress."
  type        = string
  default     = null

  validation {
    condition = (
      var.logs_agent_enabled == false ||
      (var.cloud_logs_ingress_endpoint != null && var.cloud_logs_ingress_endpoint != "")
    )
    error_message = "When 'logs_agent_enabled' is enabled, you cannot set 'cloud_logs_ingress_endpoint' as null or empty string."
  }
}

variable "cloud_logs_ingress_port" {
  type        = number
  default     = 3443
  description = "The target port for the IBM Cloud Logs ingestion endpoint. The port must be 443 if you connect by using a VPE gateway, or port 3443 when you connect by using CSEs."
}
