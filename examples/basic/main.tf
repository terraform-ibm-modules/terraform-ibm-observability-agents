##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Observability Instances
##############################################################################

module "observability_instances" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-observability-instances?ref=v2.4.0"
  providers = {
    logdna.at = logdna.at
    logdna.ld = logdna.ld
  }
  resource_group_id          = module.resource_group.resource_group_id
  region                     = var.region
  logdna_plan                = "7-day"
  sysdig_plan                = "graduated-tier"
  activity_tracker_provision = false
  enable_platform_logs       = false
  enable_platform_metrics    = false
  logdna_instance_name       = "${var.prefix}-logdna"
  sysdig_instance_name       = "${var.prefix}-sysdig"
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
  default_kube_version = "${data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions[length(data.ibm_container_cluster_versions.cluster_versions.valid_openshift_versions) - 1]}_openshift"
}

resource "ibm_container_vpc_cluster" "cluster" {
  name                 = var.prefix
  vpc_id               = ibm_is_vpc.example_vpc.id
  kube_version         = local.default_kube_version
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
  source                    = "../.."
  depends_on                = [time_sleep.wait_operators]
  cluster_id                = ibm_container_vpc_cluster.cluster.id
  cluster_resource_group_id = module.resource_group.resource_group_id
  logdna_instance_name      = module.observability_instances.logdna_name
  logdna_ingestion_key      = module.observability_instances.logdna_ingestion_key
  sysdig_instance_name      = module.observability_instances.sysdig_name
  sysdig_access_key         = module.observability_instances.sysdig_access_key
  logdna_agent_tags         = var.logdna_agent_tags
}
