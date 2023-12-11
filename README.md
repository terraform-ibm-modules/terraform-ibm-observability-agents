<!-- BEGIN MODULE HOOK -->

# Terraform IBM Observability agents module

[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-observability-agents?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module deploys the following observability agents to a Red Hat OpenShift Container Platform cluster:

- Logging agent
- Monitoring agent


## Usage

```hcl
# ############################################################################
terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.38.0"
    }
  }
}
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
}

# ############################################################################
# Install observability agents
# ############################################################################

# Replace "main" with a GIT release version to lock into a specific release
module "observability_agents" {
  source                    = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents?ref=main"
  # update this with your cluster id where the agents will be installed
  cluster_id                = "cluster id"
  # update this with the Id of your IBM Cloud resource group
  cluster_resource_group_id = "resource group id"
  # update these values with names and keys from the observability instances provisioning
  log_analysis_instance_name      = "logdna instance name"
  log_analysis_ingestion_key      = "logdna ingestion key"
  cloud_monitoring_instance_name      = "sysdig name"
  cloud_monitoring_access_key         = "sysdig access key"
}
```

## Configuration for Kubernetes metadata filtering in the logging agent

You can configure the logging agent to filter log lines according to the Kubernetes resources metadata by setting the exclusion and inclusion parameters.

For example, to set the agent to return all log lines coming from the `default` Kubernetes namespace and exclude anything with a label `app.kubernetes.io/name` with value `sample-app` or an annotation `annotation.user` with value `sample-user`, include these parameters:

```text
custom_log_analysis_at_agent_line_exclusion = "label.app.kubernetes.io/name:sample-app\\, annotation.user:sample-user"
custom_log_analysis_at_agent_line_inclusion = "namespace:default"
```

The following is the corresponding DaemonSet configuration:

```text
- name: LOG_ANALYSIS_K8S_METADATA_LINE_INCLUSION
  value: "label.app.kubernetes.io/name:sample-app, annotation.user:sample-user"
- name: LOG_ANALYSIS_K8S_METADATA_LINE_EXCLUSION
  value: "namespace:default"
```

For more information, see [Configuration for Kubernetes Metadata Filtering](https://github.com/logdna/logdna-agent-v2/blob/3.8/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering).

## Required IAM access policies
You need the following permissions to run this module.

- IAM Services
  - **IBM Cloud Activity Tracker** service
      - `Viewer` platform access
      - `Reader` service access
  - **IBM Cloud Monitoring** service
      - `Viewer` platform access
      - `Reader` service access
  - **IBM Log Analysis** service
      - `Viewer` platform access
      - `Reader` service access
  - **Kubernetes** service
      - `Viewer` platform access
      - `Manager` service access

<!-- END MODULE HOOK -->
<!-- BEGIN EXAMPLES HOOK -->
## Examples

- [ Deploy basic observability agents](examples/basic)
<!-- END EXAMPLES HOOK -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.0, <1.6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.8.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.59.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.cloud_monitoring_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.log_analysis_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [ibm_container_vpc_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_vpc_cluster) | data source |
| [ibm_resource_instance.cloud_monitoring_instance](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/resource_instance) | data source |
| [ibm_resource_instance.log_analysis_instance](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/resource_instance) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_monitoring_access_key"></a> [cloud\_monitoring\_access\_key](#input\_cloud\_monitoring\_access\_key) | Access key used by the IBM Cloud Monitoring agent to communicate with the instance | `string` | `null` | no |
| <a name="input_cloud_monitoring_add_cluster_name"></a> [cloud\_monitoring\_add\_cluster\_name](#input\_cloud\_monitoring\_add\_cluster\_name) | If true, configure the cloud monitoring agent to attach a tag containing the cluster name to all metric data. | `bool` | `true` | no |
| <a name="input_cloud_monitoring_agent_tags"></a> [cloud\_monitoring\_agent\_tags](#input\_cloud\_monitoring\_agent\_tags) | array of tags to group the host metrics pushed by the cloud monitoring agent | `list(string)` | `[]` | no |
| <a name="input_cloud_monitoring_agent_version"></a> [cloud\_monitoring\_agent\_version](#input\_cloud\_monitoring\_agent\_version) | IBM Cloud Monitoring Agent Version. To lookup version run: `ibmcloud cr images --restrict ext/sysdig/agent`. If null, the default value is used. | `string` | `"12.17.1"` | no |
| <a name="input_cloud_monitoring_enabled"></a> [cloud\_monitoring\_enabled](#input\_cloud\_monitoring\_enabled) | Deploy IBM Cloud Monitoring agent | `bool` | `true` | no |
| <a name="input_cloud_monitoring_instance_name"></a> [cloud\_monitoring\_instance\_name](#input\_cloud\_monitoring\_instance\_name) | The name of the IBM Cloud Monitoring instance to use. Required if Cloud Monitoring is enabled | `string` | `null` | no |
| <a name="input_cloud_monitoring_metrics_filter"></a> [cloud\_monitoring\_metrics\_filter](#input\_cloud\_monitoring\_metrics\_filter) | To filter custom metrics, specify the Cloud Monitoring metrics to include or to exclude. See  https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics. | <pre>list(object({<br>    type = string<br>    name = string<br>  }))</pre> | `[]` | no |
| <a name="input_cloud_monitoring_resource_group_id"></a> [cloud\_monitoring\_resource\_group\_id](#input\_cloud\_monitoring\_resource\_group\_id) | Resource group that the IBM Cloud Monitoring is in. Defaults to Clusters group | `string` | `null` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Cluster id to add to agents to | `string` | n/a | yes |
| <a name="input_cluster_resource_group_id"></a> [cluster\_resource\_group\_id](#input\_cluster\_resource\_group\_id) | Resource group of the cluster | `string` | n/a | yes |
| <a name="input_log_analysis_add_cluster_name"></a> [log\_analysis\_add\_cluster\_name](#input\_log\_analysis\_add\_cluster\_name) | If true, configure the log analysis agent to attach a tag containing the cluster name to all log messages. | `bool` | `true` | no |
| <a name="input_log_analysis_agent_custom_line_exclusion"></a> [log\_analysis\_agent\_custom\_line\_exclusion](#input\_log\_analysis\_agent\_custom\_line\_exclusion) | Log Analysis agent custom configuration for line exclusion setting LOG\_ANALYSIS\_K8S\_METADATA\_LINE\_EXCLUSION. | `string` | `null` | no |
| <a name="input_log_analysis_agent_custom_line_inclusion"></a> [log\_analysis\_agent\_custom\_line\_inclusion](#input\_log\_analysis\_agent\_custom\_line\_inclusion) | Log Analysis agent custom configuration for line inclusion setting LOG\_ANALYSIS\_K8S\_METADATA\_LINE\_INCLUSION. | `string` | `null` | no |
| <a name="input_log_analysis_agent_tags"></a> [log\_analysis\_agent\_tags](#input\_log\_analysis\_agent\_tags) | array of tags to group the host logs pushed by the log analysis agent | `list(string)` | `[]` | no |
| <a name="input_log_analysis_agent_version"></a> [log\_analysis\_agent\_version](#input\_log\_analysis\_agent\_version) | Version of the agent to deploy. To lookup version run: `ibmcloud cr images --restrict ext/logdna-agent`. If null, the default value is used. | `string` | `"3.9.0-20231204.f89f0d6c94267329"` | no |
| <a name="input_log_analysis_enabled"></a> [log\_analysis\_enabled](#input\_log\_analysis\_enabled) | Deploy IBM Cloud Logging agent | `bool` | `true` | no |
| <a name="input_log_analysis_ingestion_key"></a> [log\_analysis\_ingestion\_key](#input\_log\_analysis\_ingestion\_key) | Ingestion key for the IBM Cloud Logging agent to communicate with the instance | `string` | `null` | no |
| <a name="input_log_analysis_instance_name"></a> [log\_analysis\_instance\_name](#input\_log\_analysis\_instance\_name) | IBM Cloud Logging instance to use. Required if Log Analysis is enabled | `string` | `null` | no |
| <a name="input_log_analysis_resource_group_id"></a> [log\_analysis\_resource\_group\_id](#input\_log\_analysis\_resource\_group\_id) | Resource group the IBM Cloud Logging instance is in. Defaults to Clusters group | `string` | `null` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- BEGIN CONTRIBUTING HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
<!-- Source for this readme file: https://github.com/terraform-ibm-modules/common-dev-assets/tree/main/module-assets/ci/module-template-automation -->
<!-- END CONTRIBUTING HOOK -->
