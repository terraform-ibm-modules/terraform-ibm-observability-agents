##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.6"
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


module "trusted_profile" {
  source                      = "terraform-ibm-modules/trusted-profile/ibm"
  version                     = "3.2.8"
  trusted_profile_name        = "${var.prefix}-profile"
  trusted_profile_description = "Logs agent Trusted Profile"
  # As a `Sender`, you can send logs to your IBM Cloud Logs service instance - but not query or tail logs. This role is meant to be used by agents and routers sending logs.
  trusted_profile_policies = [{
    roles             = ["Sender"]
    unique_identifier = "${var.prefix}-profile-0"
    resources = [{
      service = "logs"
    }]
  }]
  # Set up fine-grained authorization for `logs-agent` running in ROKS cluster in `ibm-observe` namespace.
  trusted_profile_links = [{
    cr_type           = "ROKS_SA"
    unique_identifier = "${var.prefix}-profile-0"
    links = [{
      crn       = module.ocp_base.cluster_crn
      namespace = local.logs_agent_namespace
      name      = local.logs_agent_name
    }]
    }
  ]
}

########################################################################################################################
# VPC + Subnet + Public Gateway
#
# NOTE: This is a very simple VPC with single subnet in a single zone with a public gateway enabled, that will allow
# all traffic ingress/egress by default.
# For production use cases this would need to be enhanced by adding more subnets and zones for resiliency, and
# ACLs/Security Groups for network security.
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

resource "ibm_is_public_gateway" "gateway" {
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "subnet_zone_1" {
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway.id
}

########################################################################################################################
# OCP VPC cluster (single zone)
########################################################################################################################

locals {
  cluster_vpc_subnets = {
    default = [
      {
        id         = ibm_is_subnet.subnet_zone_1.id
        cidr_block = ibm_is_subnet.subnet_zone_1.ipv4_cidr_block
        zone       = ibm_is_subnet.subnet_zone_1.zone
      }
    ]
  }

  worker_pools = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      operating_system = "REDHAT_8_64"
      workers_per_zone = 2 # minimum of 2 is allowed when using single zone
    }
  ]
}

module "ocp_base" {
  source               = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version              = "3.75.5"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  tags                 = var.resource_tags
  cluster_name         = var.prefix
  force_delete_storage = true
  vpc_id               = ibm_is_vpc.vpc.id
  vpc_subnets          = local.cluster_vpc_subnets
  ocp_version          = var.ocp_version
  worker_pools         = local.worker_pools
  access_tags          = var.access_tags
  ocp_entitlement      = var.ocp_entitlement
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = module.ocp_base.cluster_id
  resource_group_id = module.resource_group.resource_group_id
}

##############################################################################
# Observability Instance
##############################################################################

module "observability_instances" {
  source                         = "terraform-ibm-modules/observability-instances/ibm"
  version                        = "3.5.3"
  resource_group_id              = module.resource_group.resource_group_id
  region                         = var.region
  cloud_logs_plan                = "standard"
  cloud_monitoring_plan          = "graduated-tier"
  enable_platform_metrics        = false
  cloud_logs_instance_name       = "${var.prefix}-cloud-logs"
  cloud_monitoring_instance_name = "${var.prefix}-cloud-monitoring"
}

data "ibm_is_security_groups" "vpc_security_groups" {
  depends_on = [module.ocp_base]
  vpc_id     = ibm_is_vpc.vpc.id
}

# The below code creates a VPE for Cloud logs in the provisioned VPC which allows the agents to access the private Cloud Logs Ingress endpoint.
module "vpe" {
  source   = "terraform-ibm-modules/vpe-gateway/ibm"
  version  = "4.8.6"
  region   = var.region
  prefix   = var.prefix
  vpc_id   = ibm_is_vpc.vpc.id
  vpc_name = "${var.prefix}-vpc"
  subnet_zone_list = [
    {
      id   = ibm_is_subnet.subnet_zone_1.id
      name = ibm_is_subnet.subnet_zone_1.name
      zone = ibm_is_subnet.subnet_zone_1.zone
    }
  ]
  resource_group_id  = module.resource_group.resource_group_id
  security_group_ids = [for group in data.ibm_is_security_groups.vpc_security_groups.security_groups : group.id if group.name == "kube-${module.ocp_base.cluster_id}"] # Select only security group attached to the Cluster
  cloud_service_by_crn = [
    {
      crn          = module.observability_instances.cloud_logs_crn
      service_name = "logs"
    }
  ]
  service_endpoints = "private"
}

##############################################################################
# Observability Agents
##############################################################################

module "observability_agents" {
  source                    = "../.."
  depends_on                = [module.vpe]
  cluster_id                = module.ocp_base.cluster_id
  cluster_resource_group_id = module.resource_group.resource_group_id
  # Cloud Logs agent
  logs_agent_trusted_profile  = module.trusted_profile.trusted_profile.id
  logs_agent_namespace        = local.logs_agent_namespace
  logs_agent_name             = local.logs_agent_name
  cloud_logs_ingress_endpoint = module.observability_instances.cloud_logs_ingress_private_endpoint
  cloud_logs_ingress_port     = 443
  # example of how to add additional metadata to the logs agents
  logs_agent_additional_metadata = [{
    key   = "cluster_id"
    value = module.ocp_base.cluster_id
  }]
  # example of how to add additional log source path
  logs_agent_additional_log_source_paths = ["/logs/*.log"]
  # Monitoring agent
  cloud_monitoring_access_key = module.observability_instances.cloud_monitoring_access_key
  # example of how to include / exclude metrics - more info https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_log_metrics
  cloud_monitoring_metrics_filter   = [{ type = "exclude", name = "metricA.*" }, { type = "include", name = "metricB.*" }]
  cloud_monitoring_container_filter = [{ type = "exclude", parameter = "kubernetes.namespace.name", name = "kube-system" }]
  cloud_monitoring_agent_tags       = var.resource_tags
  cloud_monitoring_instance_region  = module.observability_instances.region
}
