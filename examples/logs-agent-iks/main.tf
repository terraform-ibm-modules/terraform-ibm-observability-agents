##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Trusted Profile
##############################################################################

locals {
  logs_agent_namespace = "ibm-observe"
  logs_agent_name      = "logs-agent"
}

# As a `Sender`, you can send logs to your IBM Cloud Logs service instance - but not query or tail logs. This role is meant to be used by agents and routers sending logs.
module "iam_service_id" {
  source                          = "terraform-ibm-modules/iam-service-id/ibm"
  version                         = "1.2.0"
  iam_service_id_name             = "${var.prefix}-service-id"
  iam_service_id_description      = "Logs Agent service id"
  iam_service_id_apikey_provision = true
  iam_service_policies = {
    logs = {
      roles = ["Sender"]
      resources = [{
        service = "logs"
      }]
    }
  }
}

##############################################################################
# Create VPC and IKS Cluster
##############################################################################

resource "ibm_is_vpc" "example_vpc" {
  name           = "${var.prefix}-vpc"
  resource_group = module.resource_group.resource_group_id
  tags           = var.resource_tags
}

resource "ibm_is_subnet" "testacc_subnet" {
  name                     = "${var.prefix}-subnet"
  vpc                      = ibm_is_vpc.example_vpc.id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  resource_group           = module.resource_group.resource_group_id
}

# Lookup the current default kube version
data "ibm_container_cluster_versions" "cluster_versions" {}
locals {
  default_version = data.ibm_container_cluster_versions.cluster_versions.default_kube_version
}

resource "ibm_container_vpc_cluster" "cluster" {
  name                 = var.prefix
  vpc_id               = ibm_is_vpc.example_vpc.id
  kube_version         = local.default_version
  flavor               = "bx2.4x16"
  worker_count         = "2"
  force_delete_storage = true
  wait_till            = "IngressReady"
  zones {
    subnet_id = ibm_is_subnet.testacc_subnet.id
    name      = "${var.region}-1"
  }
  resource_group_id = module.resource_group.resource_group_id
  tags              = var.resource_tags
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = ibm_container_vpc_cluster.cluster.id
  resource_group_id = module.resource_group.resource_group_id
}

# Sleep to allow RBAC sync on cluster
resource "time_sleep" "wait_operators" {
  depends_on      = [data.ibm_container_cluster_config.cluster_config]
  create_duration = "45s"
}

##############################################################################
# Observability Instance
##############################################################################


module "observability_instances" {
  source  = "terraform-ibm-modules/observability-instances/ibm"
  version = "2.18.1"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  resource_group_id              = module.resource_group.resource_group_id
  region                         = var.region
  cloud_logs_plan                = "standard"
  cloud_monitoring_plan          = "graduated-tier"
  activity_tracker_provision     = false
  enable_platform_logs           = false
  enable_platform_metrics        = false
  log_analysis_provision         = false
  cloud_logs_instance_name       = "${var.prefix}-cloud-logs"
  cloud_monitoring_instance_name = "${var.prefix}-cloud-monitoring"
}

##############################################################################
# Observability Agents
##############################################################################

module "observability_agents" {
  source                    = "../.."
  depends_on                = [time_sleep.wait_operators]
  cluster_id                = ibm_container_vpc_cluster.cluster.id
  cluster_resource_group_id = module.resource_group.resource_group_id
  # Logs Agent
  logs_agent_enabled          = true
  logs_agent_iam_mode         = "IAMAPIKey"
  logs_agent_iam_api_key      = module.iam_service_id.service_id_apikey
  logs_agent_namespace        = local.logs_agent_namespace
  logs_agent_name             = local.logs_agent_name
  cloud_logs_ingress_endpoint = module.observability_instances.cloud_logs_ingress_private_endpoint
  cloud_logs_ingress_port     = 3443
  logs_agent_enable_scc       = false
  # Monitoring agent
  cloud_monitoring_enabled         = true
  cloud_monitoring_access_key      = module.observability_instances.cloud_monitoring_access_key
  cloud_monitoring_instance_region = module.observability_instances.region
}
