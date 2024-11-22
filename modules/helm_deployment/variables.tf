# Kubernetes Provider Configuration
variable "host" {
  description = "Kubernetes cluster host"
  type        = string
}

variable "token" {
  description = "Kubernetes cluster token"
  type        = string
  sensitive   = true
}

# IBM Cloud Configuration
variable "ibmcloud_api_key" {
  description = "IBM Cloud API key"
  type        = string
  sensitive   = true
}

# Helm Provider Configuration
variable "registry_url" {
  description = "URL of the Helm chart registry"
  type        = string
}

# Helm Release Configuration
variable "name" {
  description = "Name of the Helm release"
  type        = string
}

variable "chart_location" {
  description = "Location of the Helm chart"
  type        = string
}

variable "namespace" {
  description = "Namespace for the Helm release"
  type        = string
}

variable "timeout" {
  description = "Timeout for the Helm release"
  type        = number
  default     = 1200
}

variable "wait" {
  description = "Wait for the Helm release to be ready"
  type        = bool
  default     = true
}

variable "recreate_pods" {
  description = "Recreate pods if necessary"
  type        = bool
  default     = true
}

variable "force_update" {
  description = "Force update the Helm release"
  type        = bool
  default     = true
}

variable "reset_values" {
  description = "Reset values for the Helm release"
  type        = bool
  default     = true
}

# Cluster Configuration
variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "region" {
  description = "Region of the cluster"
  type        = string
}

# Helm Values Configuration
variable "values" {
  description = "List of values to set in the Helm release"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Local Exec Provisioner Configuration
variable "local_exec_commands" {
  description = "List of commands and associated environments for the local-exec provisioner"
  type = list(object({
    command     = string
    environment = map(string)
  }))
  default = []
}
