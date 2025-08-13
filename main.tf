##############################################################################
# terraform-ibm-observability-agents
##############################################################################

# Lookup cluster name from ID. The is_vpc_cluster variable defines whether to use the VPC data block or the Classic data block
data "ibm_container_vpc_cluster" "cluster" {
  count             = var.is_vpc_cluster ? 1 : 0
  name              = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
  wait_till         = var.wait_till
  wait_till_timeout = var.wait_till_timeout
}

data "ibm_container_cluster" "cluster" {
  count             = var.is_vpc_cluster ? 0 : 1
  name              = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
  wait_till         = var.wait_till
  wait_till_timeout = var.wait_till_timeout
}

# Download cluster config which is required to connect to cluster
data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].name : data.ibm_container_cluster.cluster[0].name
  resource_group_id = var.cluster_resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null value represents default
}

locals {
  # LOCALS
  cluster_name                      = var.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].resource_name : data.ibm_container_cluster.cluster[0].resource_name # Not publically documented in provider. See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4485
  cloud_monitoring_chart_location   = "${path.module}/chart/sysdig-agent"
  cloud_monitoring_image_tag_digest = "14.1.1@sha256:60287a9413c79a424aa033ab943957f4f0031eddf7b66d26e764253026bd3c78" # datasource: icr.io/ext/sysdig/agent
  cloud_monitoring_agent_registry   = "icr.io/ext/sysdig/agent"
  cloud_monitoring_agent_tags       = var.cloud_monitoring_add_cluster_name ? concat(["ibm.containers-kubernetes.cluster.name:${local.cluster_name}"], var.cloud_monitoring_agent_tags) : var.cloud_monitoring_agent_tags
  cloud_monitoring_host             = var.cloud_monitoring_enabled ? var.cloud_monitoring_endpoint_type == "private" ? "ingest.private.${var.cloud_monitoring_instance_region}.monitoring.cloud.ibm.com" : "logs.${var.cloud_monitoring_instance_region}.monitoring.cloud.ibm.com" : null
}

/** Cloud Monitoring Configuration Start **/
resource "helm_release" "cloud_monitoring_agent" {
  count = var.cloud_monitoring_enabled ? 1 : 0

  name             = var.cloud_monitoring_agent_name
  chart            = local.cloud_monitoring_chart_location
  namespace        = var.cloud_monitoring_agent_namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true
  reset_values     = true

  set = [
    {
      name  = "metadata.name"
      type  = "string"
      value = var.cloud_monitoring_agent_name
    },
    {
      name  = "image.version"
      type  = "string"
      value = local.cloud_monitoring_image_tag_digest
    },
    {
      name  = "image.registry"
      type  = "string"
      value = local.cloud_monitoring_agent_registry
    },
    {
      name  = "config.clustername"
      type  = "string"
      value = local.cluster_name
    },
    {
      name  = "config.host"
      type  = "string"
      value = local.cloud_monitoring_host
    },
    {
      name  = "secret.name"
      type  = "string"
      value = var.cloud_monitoring_secret_name
    },
    {
      name  = "config.tags"
      type  = "string"
      value = join("\\,", local.cloud_monitoring_agent_tags)
    },
    {
      name  = "ebpf.enabled"
      value = var.enable_universal_ebpf
    },
    {
      name  = "ebpf.kind"
      value = "universal_ebpf"
    }
  ]

  set_sensitive = [{
    name  = "secret.key"
    type  = "string"
    value = var.cloud_monitoring_access_key
  }]

  values = [yamlencode({
    metrics_filter = var.cloud_monitoring_metrics_filter
    }), yamlencode({
    tolerations = var.cloud_monitoring_agent_tolerations
    }), yamlencode({
    container_filter = var.cloud_monitoring_container_filter
  })]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh ${var.cloud_monitoring_agent_name} ${var.cloud_monitoring_agent_namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
/** Cloud Monitoring Configuration End **/


/** Logs Agent Configuration Start **/
module "logs_agent" {
  count                                  = var.logs_agent_enabled ? 1 : 0
  source                                 = "./modules/logs-agent"
  cluster_id                             = var.cluster_id
  cluster_resource_group_id              = var.cluster_resource_group_id
  cluster_config_endpoint_type           = var.cluster_config_endpoint_type
  logs_agent_name                        = var.logs_agent_name
  logs_agent_namespace                   = var.logs_agent_namespace
  logs_agent_trusted_profile             = var.logs_agent_trusted_profile
  logs_agent_iam_api_key                 = var.logs_agent_iam_api_key
  logs_agent_tolerations                 = var.logs_agent_tolerations
  logs_agent_additional_log_source_paths = var.logs_agent_additional_log_source_paths
  logs_agent_exclude_log_source_paths    = var.logs_agent_exclude_log_source_paths
  logs_agent_selected_log_source_paths   = var.logs_agent_selected_log_source_paths
  logs_agent_log_source_namespaces       = var.logs_agent_log_source_namespaces
  logs_agent_iam_mode                    = var.logs_agent_iam_mode
  logs_agent_iam_environment             = var.logs_agent_iam_environment
  logs_agent_additional_metadata         = var.logs_agent_additional_metadata
  logs_agent_enable_scc                  = var.logs_agent_enable_scc
  cloud_logs_ingress_endpoint            = var.cloud_logs_ingress_endpoint
  cloud_logs_ingress_port                = var.cloud_logs_ingress_port
  is_vpc_cluster                         = var.is_vpc_cluster
  wait_till                              = var.wait_till
  wait_till_timeout                      = var.wait_till_timeout
}
/** Logs Agent Configuration End **/
