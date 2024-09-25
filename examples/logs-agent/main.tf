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
  logs_agent_name      = "logger-agent"
}

module "trusted_profile" {
  source                      = "terraform-ibm-modules/trusted-profile/ibm"
  version                     = "1.0.4"
  trusted_profile_name        = "${var.prefix}-profile"
  trusted_profile_description = "Example Trusted Profile"

  trusted_profile_policies = [{
    roles = ["Sender"]
    resources = [{
      service = "logs"
    }]
  }]

  trusted_profile_links = [{
    cr_type = var.is_openshift ? "ROKS_SA" : "IKS_SA"
    links = [{
      crn       = ibm_container_vpc_cluster.cluster.crn
      namespace = local.logs_agent_namespace
      name      = local.logs_agent_name
    }]
    }
  ]
}

##############################################################################
# Create VPC and Cluster
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

resource "ibm_resource_instance" "cos_instance" {
  count             = var.is_openshift ? 1 : 0
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
  default_version = var.is_openshift ? "${data.ibm_container_cluster_versions.cluster_versions.default_openshift_version}_openshift" : data.ibm_container_cluster_versions.cluster_versions.default_kube_version
}

resource "ibm_container_vpc_cluster" "cluster" {
  name                 = var.prefix
  vpc_id               = ibm_is_vpc.example_vpc.id
  kube_version         = local.default_version
  flavor               = "bx2.4x16"
  worker_count         = "2"
  entitlement          = var.is_openshift ? "cloud_pak" : null
  cos_instance_crn     = var.is_openshift ? ibm_resource_instance.cos_instance[0].id : null
  force_delete_storage = true
  wait_till            = "Normal"
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
  create_duration = "5s"
}

##############################################################################
# Observability Instance
##############################################################################


module "observability_instance" {
  source  = "terraform-ibm-modules/observability-instances/ibm"
  version = "2.16.0"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  region                     = var.region
  log_analysis_provision     = false
  cloud_monitoring_provision = false
  activity_tracker_provision = false
  cloud_logs_instance_name   = "${var.prefix}-cloud-logs"
  resource_group_id          = module.resource_group.resource_group_id
  cloud_logs_plan            = "standard"
  cloud_logs_tags            = var.resource_tags
  cloud_logs_access_tags     = var.access_tags
}

data "ibm_is_security_groups" "vpc_security_groups" {
  depends_on = [ibm_container_vpc_cluster.cluster]
  vpc_id     = ibm_is_vpc.example_vpc.id
}

module "vpe" {
  source   = "terraform-ibm-modules/vpe-gateway/ibm"
  version  = "4.3.0"
  region   = var.region
  prefix   = var.prefix
  vpc_id   = ibm_is_vpc.example_vpc.id
  vpc_name = "${var.prefix}-vpc"
  subnet_zone_list = [
    {
      name = ibm_is_subnet.testacc_subnet.name
      id   = ibm_is_subnet.testacc_subnet.id
      zone = ibm_is_subnet.testacc_subnet.zone
    }
  ]
  resource_group_id  = module.resource_group.resource_group_id
  security_group_ids = [for group in data.ibm_is_security_groups.vpc_security_groups.security_groups : group.id if group.name == "kube-${ibm_container_vpc_cluster.cluster.id}"] # Select only security group attached to the Cluster
  cloud_service_by_crn = [
    {
      crn          = module.observability_instance.cloud_logs_crn
      service_name = "logs"
    }
  ]
  service_endpoints = "private"
}

##############################################################################
# Observability Agents
##############################################################################

module "observability_agents" {
  source                                 = "../../modules/logs-agent-module"
  depends_on                             = [time_sleep.wait_operators, module.vpe]
  cluster_id                             = ibm_container_vpc_cluster.cluster.id
  cluster_resource_group_id              = module.resource_group.resource_group_id
  logs_agent_enabled                     = true
  logs_agent_trusted_profile             = module.trusted_profile.trusted_profile.id
  logs_agent_namespace                   = local.logs_agent_namespace
  logs_agent_name                        = local.logs_agent_name
  logs_agent_enable_direct_to_cloud_logs = true
  cloud_logs_ingress_endpoint            = module.observability_instance.cloud_logs_ingress_private_endpoint
  cloud_logs_ingress_port                = 443
  logs_agent_enable_scc                  = var.is_openshift ? true : false
}
