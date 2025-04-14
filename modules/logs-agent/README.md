# Logs Agents module

You can use this module to deploy Logs Agent in your cluster. The agent can collect and route application logs from a Red Hat OpenShift or Kubernetes cluster to an IBM Cloud Logs of your choice.

## Usage

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
  ibmcloud_api_key = "api key value"  # pragma: allowlist secret
}

provider "helm" {
  kubernetes {
    host                   = data.ibm_container_cluster_config.cluster_config.host
    token                  = data.ibm_container_cluster_config.cluster_config.token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
  }
  # IBM Cloud credentials are required to authenticate to the helm repo
  registry {
    url = "oci://icr.io/ibm/observe/logs-agent-helm"
    username = "iamapikey"
    password = "XXXXXXXXXXXXXXXXX" # replace with an IBM cloud apikey
  }
}

# ############################################################################
# Install observability agents
# ############################################################################

module "logs_agent_module" {
  source = "terraform-ibm-modules/observability-agents/ibm//modules/logs-agent"
  # update this with your cluster id where the agents will be installed
  cluster_id = "cluster id"
  # update this with the Id of your IBM Cloud resource group
  cluster_resource_group_id = "resource group id"
  # Logs Agent variables
  logs_agent_trusted_profile  = "XXXXXXXX"
  cloud_logs_ingress_endpoint = "<cloud-logs-instance-guid>.ingress.us-south.logs.cloud.ibm.com"
  cloud_logs_ingress_port     = 443
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.11.0, <3.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.59.0, <2.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.logs_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [ibm_container_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster) | data source |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [ibm_container_vpc_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_vpc_cluster) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_logs_ingress_endpoint"></a> [cloud\_logs\_ingress\_endpoint](#input\_cloud\_logs\_ingress\_endpoint) | The host for IBM Cloud Logs ingestion. Ensure you use the ingress endpoint. See https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-endpoints_ingress. | `string` | `null` | no |
| <a name="input_cloud_logs_ingress_port"></a> [cloud\_logs\_ingress\_port](#input\_cloud\_logs\_ingress\_port) | The target port for the IBM Cloud Logs ingestion endpoint. The port must be 443 if you connect by using a VPE gateway, or port 3443 when you connect by using CSEs. | `number` | `3443` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | The type of endpoint to use for the cluster config access: `default`, `private`, `vpe`, or `link`. The `default` value uses the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ID of the cluster to deploy the agents. | `string` | n/a | yes |
| <a name="input_cluster_resource_group_id"></a> [cluster\_resource\_group\_id](#input\_cluster\_resource\_group\_id) | The resource group ID of the cluster. | `string` | n/a | yes |
| <a name="input_is_vpc_cluster"></a> [is\_vpc\_cluster](#input\_is\_vpc\_cluster) | Specify true if the target cluster for the agents is a VPC cluster, false if it is a classic cluster. | `bool` | `true` | no |
| <a name="input_logs_agent_additional_log_source_paths"></a> [logs\_agent\_additional\_log\_source\_paths](#input\_logs\_agent\_additional\_log\_source\_paths) | The list of additional log sources. By default, the Logs agent collects logs from a single source at `/var/log/containers/*.log`. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_additional_metadata"></a> [logs\_agent\_additional\_metadata](#input\_logs\_agent\_additional\_metadata) | The list of additional metadata fields to add to the routed logs. | <pre>list(object({<br/>    key   = optional(string)<br/>    value = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_logs_agent_enable_scc"></a> [logs\_agent\_enable\_scc](#input\_logs\_agent\_enable\_scc) | Whether to enable creation of Security Context Constraints in Openshift. When installing on an OpenShift cluster, this setting is mandatory to configure permissions for pods within your cluster. | `bool` | `true` | no |
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
| <a name="input_wait_till"></a> [wait\_till](#input\_wait\_till) | To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal` | `string` | `"Normal"` | no |
| <a name="input_wait_till_timeout"></a> [wait\_till\_timeout](#input\_wait\_till\_timeout) | Timeout for wait\_till in minutes. | `number` | `90` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
