##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Trusted Profile
##############################################################################

locals {
  logs_routing_agent_namespace = "ibm-observe"
  logs_routing_agent_name      = "logger-agent"
}

module "trusted_profile" {
  source                      = "terraform-ibm-modules/trusted-profile/ibm"
  version                     = "1.0.4"
  trusted_profile_name        = "${var.prefix}-profile"
  trusted_profile_description = "Example Trusted Profile"

  trusted_profile_policies = [{
    roles = ["Writer"]
    resources = [{
      service = "logs-router"
    }]
    }, {
    roles = ["Viewer"]
    resources = [{
      service = "metrics-router"
    }]
  }]

  trusted_profile_links = [{
    cr_type = var.is_openshift ? "ROKS_SA" : "IKS_SA"
    links = [{
      crn       = ibm_container_vpc_cluster.cluster.crn
      namespace = local.logs_routing_agent_namespace
      name      = local.logs_routing_agent_name
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
# Observability Agents
##############################################################################

module "observability_agents" {
  source                           = "../../modules/logs-routing-module"
  depends_on                       = [time_sleep.wait_operators]
  cluster_id                       = ibm_container_vpc_cluster.cluster.id
  cluster_resource_group_id        = module.resource_group.resource_group_id
  logs_routing_enabled             = true
  logs_routing_region              = var.region
  logs_routing_trusted_profile     = module.trusted_profile.trusted_profile.id
  logs_routing_agent_namespace     = local.logs_routing_agent_namespace
  logs_routing_agent_name          = local.logs_routing_agent_name
}