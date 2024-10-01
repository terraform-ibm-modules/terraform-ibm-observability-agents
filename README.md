# Terraform IBM Observability agents module

[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-observability-agents?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module deploys the following observability agents to an IBM Cloud Red Hat OpenShift Container Platform or Kubernetes cluster:

- [Logs agent](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-about)
- [Monitoring agent](https://cloud.ibm.com/docs/monitoring?topic=monitoring-about-collect-metrics)
- [DEPRECATED: Log Analysis agent](https://cloud.ibm.com/docs/log-analysis?topic=log-analysis-log_analysis_agent)

> [!IMPORTANT]
> The IBM Log Analysis service is deprecated. [IBM Cloud Logs](https://www.ibm.com/products/cloud-logs) is the replacement service and is now the default agent created with this module.


<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-observability-agents](#terraform-ibm-observability-agents)
* [Submodules](./modules)
    * [logs-agent](./modules/logs-agent)
* [Examples](./examples)
    * [Monitoring agent + Cloud Logs agent on Kubernetes using CSE ingress endpoint with an apikey](./examples/logs-agent-iks)
    * [Monitoring agent + Cloud Logs agent on OCP using VPE ingress endpoint with a Trusted Profile](./examples/logs-agent-roks)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->

## terraform-ibm-observability-agents

### Usage

```hcl
# ############################################################################
# Init cluster config for helm
# ############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  # update this value with the Id of the cluster where these agents will be provisioned
  cluster_name_id = "cluster_id"
}

# ############################################################################
# Config providers
# ############################################################################

provider "ibm" {
  # update this value with your IBM Cloud API key value
  ibmcloud_api_key = "XXXXXXXXXXXXXXXXX"
}

provider "helm" {
  kubernetes {
    host                   = data.ibm_container_cluster_config.cluster_config.host
    token                  = data.ibm_container_cluster_config.cluster_config.token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
  }
}

# ############################################################################
# Install observability agents
# ############################################################################

module "observability_agents" {
  source                           = "terraform-ibm-modules/observability-agents/ibm"
  version                          = "X.X.X" # Replace "X.X.X" with a release version to lock into a specific release
  is_vpc_cluster                   = true # Change to false if target cluster is running on classic infrastructure
  cluster_id                       = "cluster id" # update this with your cluster id where the agents will be installed
  cluster_resource_group_id        = "resource group id" # update this with the Id of your IBM Cloud resource group
  cloud_monitoring_access_key      = "XXXXXXXX"
  cloud_monitoring_instance_region = "us-south"
  # Logs Agent variables
  logs_agent_trusted_profile  = "XXXXXXXX"
  cloud_logs_ingress_endpoint = "<cloud-logs-instance-guid>.ingress.us-south.logs.cloud.ibm.com"
  cloud_logs_ingress_port     = 443
}
```

### (DEPRECATED) Log Analysis agent configuration for Kubernetes metadata filtering

You can configure the logging agent to filter log lines according to the Kubernetes resources metadata by setting the exclusion and inclusion parameters.

For example, to set the agent to return all log lines coming from the `default` Kubernetes namespace and exclude anything with a label `app.kubernetes.io/name` with value `sample-app` or an annotation `annotation.user` with value `sample-user`, include these parameters:

```text
custom_log_analysis_at_agent_line_exclusion = "label.app.kubernetes.io/name:sample-app\\, annotation.user:sample-user"
custom_log_analysis_at_agent_line_inclusion = "namespace:default"
```

The following is the corresponding DaemonSet configuration:

```text
- name: LOGDNA_K8S_METADATA_LINE_INCLUSION
  value: "label.app.kubernetes.io/name:sample-app, annotation.user:sample-user"
- name: LOGDNA_K8S_METADATA_LINE_EXCLUSION
  value: "namespace:default"
```

For more information, see [Configuration for Kubernetes Metadata Filtering](https://github.com/logdna/logdna-agent-v2/blob/3.8/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering).

### Required IAM access policies
You need the following permissions to run this module.

- Service
    - **Resource group only**
        - `Viewer` access on the specific resource group
    - **Kubernetes** service
        - `Viewer` platform access
        - `Manager` service access

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.11.0, <3.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.59.0, <2.0.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_logs_agent"></a> [logs\_agent](#module\_logs\_agent) | ./modules/logs-agent | n/a |

### Resources

| Name | Type |
|------|------|
| [helm_release.cloud_monitoring_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.log_analysis_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [ibm_container_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster) | data source |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [ibm_container_vpc_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_vpc_cluster) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_logs_ingress_endpoint"></a> [cloud\_logs\_ingress\_endpoint](#input\_cloud\_logs\_ingress\_endpoint) | The host for IBM Cloud Logs ingestion. Ensure you use the ingress endpoint. See https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-endpoints_ingress. | `string` | `null` | no |
| <a name="input_cloud_logs_ingress_port"></a> [cloud\_logs\_ingress\_port](#input\_cloud\_logs\_ingress\_port) | The target port for the IBM Cloud Logs ingestion endpoint. The port must be 443 if you connect by using a VPE gateway, or port 3443 when you connect by using CSEs. | `number` | `3443` | no |
| <a name="input_cloud_monitoring_access_key"></a> [cloud\_monitoring\_access\_key](#input\_cloud\_monitoring\_access\_key) | Access key used by the IBM Cloud Monitoring agent to communicate with the instance | `string` | `null` | no |
| <a name="input_cloud_monitoring_add_cluster_name"></a> [cloud\_monitoring\_add\_cluster\_name](#input\_cloud\_monitoring\_add\_cluster\_name) | If true, configure the cloud monitoring agent to attach a tag containing the cluster name to all metric data. | `bool` | `true` | no |
| <a name="input_cloud_monitoring_agent_name"></a> [cloud\_monitoring\_agent\_name](#input\_cloud\_monitoring\_agent\_name) | Cloud Monitoring agent name. Used for naming all kubernetes and helm resources on the cluster. | `string` | `"sysdig-agent"` | no |
| <a name="input_cloud_monitoring_agent_namespace"></a> [cloud\_monitoring\_agent\_namespace](#input\_cloud\_monitoring\_agent\_namespace) | Namespace where to deploy the Cloud Monitoring agent. Default value is 'ibm-observe' | `string` | `"ibm-observe"` | no |
| <a name="input_cloud_monitoring_agent_tags"></a> [cloud\_monitoring\_agent\_tags](#input\_cloud\_monitoring\_agent\_tags) | List of tags to associate to all matrics that the agent collects. NOTE: Use the 'cloud\_monitoring\_add\_cluster\_name' variable to add the cluster name as a tag. | `list(string)` | `[]` | no |
| <a name="input_cloud_monitoring_agent_tolerations"></a> [cloud\_monitoring\_agent\_tolerations](#input\_cloud\_monitoring\_agent\_tolerations) | List of tolerations to apply to Cloud Monitoring agent. | <pre>list(object({<br/>    key               = optional(string)<br/>    operator          = optional(string)<br/>    value             = optional(string)<br/>    effect            = optional(string)<br/>    tolerationSeconds = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "operator": "Exists"<br/>  },<br/>  {<br/>    "effect": "NoSchedule",<br/>    "key": "node-role.kubernetes.io/master",<br/>    "operator": "Exists"<br/>  }<br/>]</pre> | no |
| <a name="input_cloud_monitoring_enabled"></a> [cloud\_monitoring\_enabled](#input\_cloud\_monitoring\_enabled) | Deploy IBM Cloud Monitoring agent | `bool` | `true` | no |
| <a name="input_cloud_monitoring_endpoint_type"></a> [cloud\_monitoring\_endpoint\_type](#input\_cloud\_monitoring\_endpoint\_type) | Specify the IBM Cloud Monitoring instance endpoint type (public or private) to use. Used to construct the ingestion endpoint. | `string` | `"private"` | no |
| <a name="input_cloud_monitoring_instance_region"></a> [cloud\_monitoring\_instance\_region](#input\_cloud\_monitoring\_instance\_region) | The IBM Cloud Monitoring instance region. Used to construct the ingestion endpoint. | `string` | `null` | no |
| <a name="input_cloud_monitoring_metrics_filter"></a> [cloud\_monitoring\_metrics\_filter](#input\_cloud\_monitoring\_metrics\_filter) | To filter custom metrics, specify the Cloud Monitoring metrics to include or to exclude. See https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics. | <pre>list(object({<br/>    type = string<br/>    name = string<br/>  }))</pre> | `[]` | no |
| <a name="input_cloud_monitoring_secret_name"></a> [cloud\_monitoring\_secret\_name](#input\_cloud\_monitoring\_secret\_name) | The name of the secret which will store the access key. | `string` | `"sysdig-agent"` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ID of the cluster you wish to deploy the agents in | `string` | n/a | yes |
| <a name="input_cluster_resource_group_id"></a> [cluster\_resource\_group\_id](#input\_cluster\_resource\_group\_id) | The Resource Group ID of the cluster | `string` | n/a | yes |
| <a name="input_is_vpc_cluster"></a> [is\_vpc\_cluster](#input\_is\_vpc\_cluster) | Specify true if the target cluster for the observability agents is a VPC cluster, false if it is a classic cluster. | `bool` | `true` | no |
| <a name="input_log_analysis_add_cluster_name"></a> [log\_analysis\_add\_cluster\_name](#input\_log\_analysis\_add\_cluster\_name) | DEPRECATED: If true, configure the Log Analysis agent to attach a tag containing the cluster name to all log messages. | `bool` | `true` | no |
| <a name="input_log_analysis_agent_custom_line_exclusion"></a> [log\_analysis\_agent\_custom\_line\_exclusion](#input\_log\_analysis\_agent\_custom\_line\_exclusion) | DEPRECATED: Log Analysis agent custom configuration for line exclusion setting LOGDNA\_K8S\_METADATA\_LINE\_EXCLUSION. See https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering for more info. | `string` | `null` | no |
| <a name="input_log_analysis_agent_custom_line_inclusion"></a> [log\_analysis\_agent\_custom\_line\_inclusion](#input\_log\_analysis\_agent\_custom\_line\_inclusion) | DEPRECATED: Log Analysis agent custom configuration for line inclusion setting LOGDNA\_K8S\_METADATA\_LINE\_INCLUSION. See https://github.com/logdna/logdna-agent-v2/blob/master/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering for more info. | `string` | `null` | no |
| <a name="input_log_analysis_agent_name"></a> [log\_analysis\_agent\_name](#input\_log\_analysis\_agent\_name) | DEPRECATED: Log Analysis agent name. Used for naming all kubernetes and helm resources on the cluster. | `string` | `"logdna-agent"` | no |
| <a name="input_log_analysis_agent_namespace"></a> [log\_analysis\_agent\_namespace](#input\_log\_analysis\_agent\_namespace) | DEPRECATED: Namespace where to deploy the Log Analysis agent. Default value is 'ibm-observe' | `string` | `"ibm-observe"` | no |
| <a name="input_log_analysis_agent_tags"></a> [log\_analysis\_agent\_tags](#input\_log\_analysis\_agent\_tags) | DEPRECATED: List of tags to associate to all log records that the agent collects so that you can identify the agent's data quicker in the logging UI. NOTE: Use the 'log\_analysis\_add\_cluster\_name' variable to add the cluster name as a tag. | `list(string)` | `[]` | no |
| <a name="input_log_analysis_agent_tolerations"></a> [log\_analysis\_agent\_tolerations](#input\_log\_analysis\_agent\_tolerations) | DEPRECATED: List of tolerations to apply to Log Analysis agent. | <pre>list(object({<br/>    key               = optional(string)<br/>    operator          = optional(string)<br/>    value             = optional(string)<br/>    effect            = optional(string)<br/>    tolerationSeconds = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "operator": "Exists"<br/>  }<br/>]</pre> | no |
| <a name="input_log_analysis_enabled"></a> [log\_analysis\_enabled](#input\_log\_analysis\_enabled) | DEPRECATED: Deploy IBM Cloud Log Analysis agent | `bool` | `false` | no |
| <a name="input_log_analysis_endpoint_type"></a> [log\_analysis\_endpoint\_type](#input\_log\_analysis\_endpoint\_type) | DEPRECATED: Specify the IBM Log Analysis instance endpoint type (public or private) to use. Used to construct the ingestion endpoint. | `string` | `"private"` | no |
| <a name="input_log_analysis_ingestion_key"></a> [log\_analysis\_ingestion\_key](#input\_log\_analysis\_ingestion\_key) | DEPRECATED: Ingestion key for the Log Analysis agent to communicate with the instance | `string` | `null` | no |
| <a name="input_log_analysis_instance_region"></a> [log\_analysis\_instance\_region](#input\_log\_analysis\_instance\_region) | DEPRECATED: The IBM Log Analysis instance region. Used to construct the ingestion endpoint. | `string` | `null` | no |
| <a name="input_log_analysis_secret_name"></a> [log\_analysis\_secret\_name](#input\_log\_analysis\_secret\_name) | DEPRECATED: The name of the secret which will store the Log Analysis ingestion key. | `string` | `"logdna-agent"` | no |
| <a name="input_logs_agent_additional_log_source_paths"></a> [logs\_agent\_additional\_log\_source\_paths](#input\_logs\_agent\_additional\_log\_source\_paths) | The list of additional log sources. By default, the Logs agent collects logs from a single source at `/var/log/containers/*.log`. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_additional_metadata"></a> [logs\_agent\_additional\_metadata](#input\_logs\_agent\_additional\_metadata) | The list of additional metadata fields to add to the routed logs. | <pre>list(object({<br/>    key   = optional(string)<br/>    value = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_logs_agent_enable_scc"></a> [logs\_agent\_enable\_scc](#input\_logs\_agent\_enable\_scc) | Whether to enable creation of Security Context Constraints in Openshift. When installing on an OpenShift cluster, this setting is mandatory to configure permissions for pods within your cluster. | `bool` | `true` | no |
| <a name="input_logs_agent_enabled"></a> [logs\_agent\_enabled](#input\_logs\_agent\_enabled) | Whether to deploy the Logs agent. | `bool` | `true` | no |
| <a name="input_logs_agent_exclude_log_source_paths"></a> [logs\_agent\_exclude\_log\_source\_paths](#input\_logs\_agent\_exclude\_log\_source\_paths) | The list of log sources to exclude. Specify the paths that the Logs agent ignores. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_iam_api_key"></a> [logs\_agent\_iam\_api\_key](#input\_logs\_agent\_iam\_api\_key) | The IBM Cloud API key for the Logs agent to authenticate and communicate with the IBM Cloud Logs. It is required if `logs_agent_iam_mode` is set to `IAMAPIKey`. | `string` | `null` | no |
| <a name="input_logs_agent_iam_environment"></a> [logs\_agent\_iam\_environment](#input\_logs\_agent\_iam\_environment) | IAM authentication Environment: `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`. `Production` specifies the public endpoint & `PrivateProduction` specifies the private endpoint. | `string` | `"PrivateProduction"` | no |
| <a name="input_logs_agent_iam_mode"></a> [logs\_agent\_iam\_mode](#input\_logs\_agent\_iam\_mode) | IAM authentication mode: `TrustedProfile` or `IAMAPIKey`. | `string` | `"TrustedProfile"` | no |
| <a name="input_logs_agent_log_source_namespaces"></a> [logs\_agent\_log\_source\_namespaces](#input\_logs\_agent\_log\_source\_namespaces) | The list of namespaces from which logs should be forwarded by agent. If namespaces are not listed, logs from all namespaces will be sent. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_name"></a> [logs\_agent\_name](#input\_logs\_agent\_name) | The name of the Logs agent. The name is used in all Kubernetes and Helm resources in the cluster. | `string` | `"logs-agent"` | no |
| <a name="input_logs_agent_namespace"></a> [logs\_agent\_namespace](#input\_logs\_agent\_namespace) | The namespace where the Logs agent is deployed. The default value is `ibm-observe`. | `string` | `"ibm-observe"` | no |
| <a name="input_logs_agent_selected_log_source_paths"></a> [logs\_agent\_selected\_log\_source\_paths](#input\_logs\_agent\_selected\_log\_source\_paths) | The list of specific log sources paths. Logs will only be collected from the specified log source paths. If no paths are specified, it will send logs from `/var/log/containers`. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_tolerations"></a> [logs\_agent\_tolerations](#input\_logs\_agent\_tolerations) | List of tolerations to apply to Logs agent. The default value means a pod will run on every node. | <pre>list(object({<br/>    key               = optional(string)<br/>    operator          = optional(string)<br/>    value             = optional(string)<br/>    effect            = optional(string)<br/>    tolerationSeconds = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "operator": "Exists"<br/>  }<br/>]</pre> | no |
| <a name="input_logs_agent_trusted_profile"></a> [logs\_agent\_trusted\_profile](#input\_logs\_agent\_trusted\_profile) | The IBM Cloud trusted profile ID. Used only when `logs_agent_iam_mode` is set to `TrustedProfile`. The trusted profile must have an IBM Cloud Logs `Sender` role. | `string` | `null` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
