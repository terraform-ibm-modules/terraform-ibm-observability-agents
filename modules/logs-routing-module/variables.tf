##############################################################################
# Cluster variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "The ID of the cluster to deploy the agents."
}

variable "cluster_resource_group_id" {
  type        = string
  description = "The resource group ID of the cluster."
}

variable "cluster_config_endpoint_type" {
  description = "The type of endpoint to use for the cluster config access: `default`, `private`, `vpe`, or `link`. The `default` value uses the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false # use default if null is passed in
  validation {
    error_message = "Invalid endpoint type. Valid values are `default`, `private`, `vpe`, or `link`."
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}

##############################################################################
# Logs Routing variables
##############################################################################

variable "logs_routing_enabled" {
  type        = bool
  description = "Whether to deploy the Logs Routing agent."
  default     = true
}

variable "logs_routing_agent_name" {
  description = "The name of the Logs Routing agent. The name is used in all Kubernetes and Helm resources in the cluster."
  type        = string
  default     = "logger-agent"
  nullable    = false
}

variable "logs_routing_agent_namespace" {
  type        = string
  description = "The namespace where the Logs Routing agent is deployed. The default value is `ibm-observe`."
  default     = "ibm-observe"
  nullable    = false
}

variable "logs_routing_trusted_profile" {
  type        = string
  description = "The IBM Cloud trusted profile ID. Used only when `logs_routing_iam_mode` is set to `TrustedProfile`."
  default     = null
}

variable "logs_routing_ingestion_key" {
  type        = string
  description = "The IBM Cloud API key for the Logs Routing agent to authenticate and communicate with the Logs Routing."
  sensitive   = true
  default     = null
}

variable "logs_routing_region" {
  type        = string
  description = "The region where the Logs Routing ingestion endpoint is located."
  default     = "us-east"
}

variable "logs_routing_agent_tolerations" {
  description = "List of tolerations to apply to Logs Routing agent."
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

variable "logs_routing_additional_log_source_paths" {
  type        = list(string)
  description = "The list of additional log sources. By default, the Logs Routing agent collects logs from a single source at `/var/log/containers/logger-agent-ds-*.log`."
  default     = []
  nullable    = false
}

variable "logs_routing_exclude_log_source_paths" {
  type        = list(string)
  description = "The list of log sources to exclude. Specify the paths that the Logs Routing agent ignores."
  default     = []
  nullable    = false
}

variable "logs_routing_iam_mode" {
  type        = string
  default     = "TrustedProfile"
  description = "IAM authentication mode: `TrustedProfile` or `IAMAPIKey`."
  validation {
    error_message = "The IAM mode can only be `TrustedProfile` or `IAMAPIKey`."
    condition     = contains(["TrustedProfile", "IAMAPIKey"], var.logs_routing_iam_mode)
  }
}

variable "logs_routing_iam_environment" {
  type        = string
  default     = "PrivateProduction"
  description = "IAM authentication Environment: `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`."
  validation {
    error_message = "The IAM environment can only be `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`."
    condition     = contains(["Production", "PrivateProduction", "Staging", "PrivateStaging"], var.logs_routing_iam_environment)
  }
}

variable "logs_routing_port" {
  type        = number
  default     = 3443
  description = "The target port for the ingestion endpoint. The port must be 443 if you connect by using a VPE gateway, or port 3443 when you connect by using CSEs."
  validation {
    error_message = "The Logs Routing ingestion port can only be `3443` or `443`."
    condition     = contains([3443, 443], var.logs_routing_port)
  }
}

variable "logs_routing_additional_metadata" {
  description = "The list of additional metadata fields to add to the routed logs."
  type = list(object({
    key   = optional(string)
    value = optional(string)
  }))
  default = []
}

variable "logs_routing_enable_scc" {
  description = "Whether to enable creation of Security Context Constraints in Openshift."
  type        = bool
  default     = true
}

variable "logs_routing_application_name" {
  description = "The name of the application."
  type        = string
  default     = null
}


variable "logs_routing_subsystem_name" {
  description = "The name of the sub-system."
  type        = string
  default     = null
}
