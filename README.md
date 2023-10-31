<!-- BEGIN MODULE HOOK -->

# Terraform IBM Observability agents module

[![Stable (With quality checks)](https://img.shields.io/badge/Status-Stable%20(With%20quality%20checks)-green)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-observability-agents?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module supports deploying the following observability agents to the provided OCP cluster:

* Logging (LogDNA) agent
* Monitoring (SysDig) agent

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
  logdna_instance_name      = "logdna instance name"
  logdna_ingestion_key      = "logdna ingestion key"
  sysdig_instance_name      = "sysdig name"
  sysdig_access_key         = "sysdig access key"
}
```

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
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.49.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.logdna_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.sysdig_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [ibm_container_vpc_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_vpc_cluster) | data source |
| [ibm_resource_instance.logdna_instance](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/resource_instance) | data source |
| [ibm_resource_instance.sysdig_instance](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/resource_instance) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | Cluster id to add to agents to | `string` | n/a | yes |
| <a name="input_cluster_resource_group_id"></a> [cluster\_resource\_group\_id](#input\_cluster\_resource\_group\_id) | Resource group of the cluster | `string` | n/a | yes |
| <a name="input_logdna_add_cluster_name"></a> [logdna\_add\_cluster\_name](#input\_logdna\_add\_cluster\_name) | If true, configure the logdna agent to attach a tag containing the cluster name to all log messages. | `bool` | `true` | no |
| <a name="input_logdna_agent_tags"></a> [logdna\_agent\_tags](#input\_logdna\_agent\_tags) | array of tags to group the host logs pushed by the logdna agent | `list(string)` | `[]` | no |
| <a name="input_logdna_agent_version"></a> [logdna\_agent\_version](#input\_logdna\_agent\_version) | Version of the agent to deploy. To lookup version run: `ibmcloud cr images --restrict ext/logdna-agent`. If null, the default value is used. | `string` | `"3.8.9-20231027.99c540e98137eee1"` | no |
| <a name="input_logdna_enabled"></a> [logdna\_enabled](#input\_logdna\_enabled) | Deploy IBM Cloud Logging agent | `bool` | `true` | no |
| <a name="input_logdna_ingestion_key"></a> [logdna\_ingestion\_key](#input\_logdna\_ingestion\_key) | Ingestion key for the IBM Cloud Logging agent to communicate with the instance | `string` | `null` | no |
| <a name="input_logdna_instance_name"></a> [logdna\_instance\_name](#input\_logdna\_instance\_name) | IBM Cloud Logging instance to use. Required if LogDNA is enabled | `string` | `null` | no |
| <a name="input_logdna_resource_group_id"></a> [logdna\_resource\_group\_id](#input\_logdna\_resource\_group\_id) | Resource group the IBM Cloud Logging instance is in. Defaults to Clusters group | `string` | `null` | no |
| <a name="input_sysdig_access_key"></a> [sysdig\_access\_key](#input\_sysdig\_access\_key) | Access key used by the IBM Cloud Monitoring agent to communicate with the instance | `string` | `null` | no |
| <a name="input_sysdig_add_cluster_name"></a> [sysdig\_add\_cluster\_name](#input\_sysdig\_add\_cluster\_name) | If true, configure the sysdig agent to attach a tag containing the cluster name to all log messages. | `bool` | `true` | no |
| <a name="input_sysdig_agent_tags"></a> [sysdig\_agent\_tags](#input\_sysdig\_agent\_tags) | array of tags to group the host logs pushed by the sysdig agent | `list(string)` | `[]` | no |
| <a name="input_sysdig_agent_version"></a> [sysdig\_agent\_version](#input\_sysdig\_agent\_version) | IBM Cloud Monitoring Agent Version. To lookup version run: `ibmcloud cr images --restrict ext/sysdig/agent`. If null, the default value is used. | `string` | `"12.17.1"` | no |
| <a name="input_sysdig_enabled"></a> [sysdig\_enabled](#input\_sysdig\_enabled) | Deploy IBM Cloud Monitoring agent | `bool` | `true` | no |
| <a name="input_sysdig_instance_name"></a> [sysdig\_instance\_name](#input\_sysdig\_instance\_name) | The name of the IBM Cloud Monitoring instance to use. Required if Sysdig is enabled | `string` | `null` | no |
| <a name="input_sysdig_metrics_filter"></a> [sysdig\_metrics\_filter](#input\_sysdig\_metrics\_filter) | To filter custom metrics, specify the Sysdig metrics to include or to exclude. See  https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics. | <pre>list(object({<br>    type = string<br>    name = string<br>  }))</pre> | `[]` | no |
| <a name="input_sysdig_resource_group_id"></a> [sysdig\_resource\_group\_id](#input\_sysdig\_resource\_group\_id) | Resource group that the IBM Cloud Monitoring is in. Defaults to Clusters group | `string` | `null` | no |

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
