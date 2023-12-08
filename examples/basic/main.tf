##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.1.4"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Observability Instances
##############################################################################

module "observability_instances" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-instances?ref=v2.10.1"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  resource_group_id              = module.resource_group.resource_group_id
  region                         = var.region
  log_analysis_plan              = "7-day"
  cloud_monitoring_plan          = "graduated-tier"
  activity_tracker_provision     = false
  enable_platform_logs           = false
  enable_platform_metrics        = false
  log_analysis_instance_name     = "${var.prefix}-log-analysis"
  cloud_monitoring_instance_name = "${var.prefix}-cloud-monitoring"
}

##############################################################################
# Create VPC and Cluster
##############################################################################

resource "ibm_is_vpc" "example_vpc" {
  name           = "${var.prefix}-vpc"
  resource_group = module.resource_group.resource_group_id
  tags           = var.resource_tags
}

resource "ibm_is_public_gateway" "public_gateway" {
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.example_vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "testacc_subnet" {
  name                     = "${var.prefix}-subnet"
  vpc                      = ibm_is_vpc.example_vpc.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  resource_group           = module.resource_group.resource_group_id
  public_gateway           = ibm_is_public_gateway.public_gateway.id
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.prefix}-cos"
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  resource_group_id = module.resource_group.resource_group_id
  tags              = var.resource_tags
}

# Lookup the current default kube version
data "ibm_container_cluster_versions" "cluster_versions" {}
locals {
  default_ocp_version = "${data.ibm_container_cluster_versions.cluster_versions.default_openshift_version}_openshift"
}

resource "ibm_container_vpc_cluster" "cluster" {
  name                 = var.prefix
  vpc_id               = ibm_is_vpc.example_vpc.id
  kube_version         = local.default_ocp_version
  flavor               = "bx2.4x16"
  worker_count         = "2"
  entitlement          = "cloud_pak"
  cos_instance_crn     = ibm_resource_instance.cos_instance.id
  force_delete_storage = true
  zones {
    subnet_id = ibm_is_subnet.testacc_subnet.id
    name      = "${var.region}-1"
  }
  resource_group_id = module.resource_group.resource_group_id
  tags              = var.resource_tags

  timeouts {
    delete = "2h"
    create = "3h"
  }
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = ibm_container_vpc_cluster.cluster.id
  resource_group_id = module.resource_group.resource_group_id
}

# Sleep to allow RBAC sync on cluster
resource "time_sleep" "wait_operators" {
  depends_on      = [data.ibm_container_cluster_config.cluster_config]
  create_duration = "5s"
}

##############################################################################
# Observability Agents
##############################################################################


module "observability_agents" {
  source                         = "../.."
  depends_on                     = [time_sleep.wait_operators]
  cluster_id                     = ibm_container_vpc_cluster.cluster.id
  cluster_resource_group_id      = module.resource_group.resource_group_id
  log_analysis_instance_name     = module.observability_instances.log_analysis_name
  log_analysis_ingestion_key     = module.observability_instances.log_analysis_ingestion_key
  cloud_monitoring_instance_name = module.observability_instances.cloud_monitoring_name
  cloud_monitoring_access_key    = module.observability_instances.cloud_monitoring_access_key
  log_analysis_agent_tags        = var.resource_tags
  log_analysis_add_cluster_name  = true
  # example of how to include / exclude metrics - more info https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_log_metrics
  cloud_monitoring_metrics_filter = [{ type = "exclude", name = "metricA.*" }, { type = "include", name = "metricB.*" }]
  cloud_monitoring_agent_tags     = var.resource_tags
  # Log Analysis agent custom settings to setup Kubernetes metadata logs filtering by setting
  # LOG_ANALYSIS_K8S_METADATA_LINE_INCLUSION and LOG_ANALYSIS_K8S_METADATA_LINE_EXCLUSION in the agent daemonset definition
  # Ref https://github.com/logdna/logdna-agent-v2/blob/3.8/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering
  log_analysis_agent_custom_line_exclusion = "label.app.kubernetes.io/name:sample-app\\, annotation.user:sample-user"
  log_analysis_agent_custom_line_inclusion = "namespace:default"
}
