##############################################################################
# terraform-ibm-observability-agents
##############################################################################

# Lookup cluster name from ID. The is_vpc_cluster variable defines whether to use the VPC data block or the Classic data block
data "ibm_container_vpc_cluster" "cluster" {
  count             = var.is_vpc_cluster ? 1 : 0
  name              = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
}

data "ibm_container_cluster" "cluster" {
  count             = var.is_vpc_cluster ? 0 : 1
  name              = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
}

# Download cluster config which is required to connect to cluster
data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null value represents default
}

locals {
  # LOCALS
  cluster_name                  = var.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].resource_name : data.ibm_container_cluster.cluster[0].resource_name # Not publically documented in provider. See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4485
  log_analysis_chart_location   = "${path.module}/chart/logdna-agent"
  log_analysis_image_tag_digest = "3.10.1-20240827.12afa351b661bc07@sha256:3a7ebc7fb58de67db2af15f35ba827c96a92c06e933abb4c67431854a24bd156" # datasource: icr.io/ext/logdna-agent versioning=regex:^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-(?<build>\d+)
  log_analysis_agent_registry   = "icr.io/ext/logdna-agent"
  log_analysis_agent_tags       = var.log_analysis_add_cluster_name ? concat([local.cluster_name], var.log_analysis_agent_tags) : var.log_analysis_agent_tags
  log_analysis_host             = var.log_analysis_enabled ? var.log_analysis_endpoint_type == "private" ? "logs.private.${var.log_analysis_instance_region}.logging.cloud.ibm.com" : "logs.${var.log_analysis_instance_region}.logging.cloud.ibm.com" : null
  # The directory in which the logdna agent will store its state database.
  # Note that the agent must have write access to the directory (handlded by the initContainer) and be a persistent volume.
  log_analysis_agent_db_path        = "/var/lib/logdna"
  cloud_monitoring_chart_location   = "${path.module}/chart/sysdig-agent"
  cloud_monitoring_image_tag_digest = "13.4.1@sha256:469f3eee8d00ce563041770e875555dbabf02daa57cc489d9e66010707cdc621" # datasource: icr.io/ext/sysdig/agent
  cloud_monitoring_agent_registry   = "icr.io/ext/sysdig/agent"
  cloud_monitoring_agent_tags       = var.cloud_monitoring_add_cluster_name ? concat(["ibm.containers-kubernetes.cluster.name:${local.cluster_name}"], var.cloud_monitoring_agent_tags) : var.cloud_monitoring_agent_tags
  cloud_monitoring_host             = var.cloud_monitoring_enabled ? var.cloud_monitoring_endpoint_type == "private" ? "ingest.private.${var.cloud_monitoring_instance_region}.monitoring.cloud.ibm.com" : "logs.${var.cloud_monitoring_instance_region}.monitoring.cloud.ibm.com" : null

  # VARIABLE VALIDATION
  log_analysis_key_validate_condition = var.log_analysis_enabled == true && var.log_analysis_instance_region == null && var.log_analysis_ingestion_key == null
  log_analysis_key_validate_msg       = "Values for 'log_analysis_ingestion_key' and 'log_analysis_instance_region' variables must be passed when 'log_analysis_enabled = true'"
  # tflint-ignore: terraform_unused_declarations
  log_analysis_key_validate_check = regex("^${local.log_analysis_key_validate_msg}$", (!local.log_analysis_key_validate_condition ? local.log_analysis_key_validate_msg : ""))

  cloud_monitoring_key_validate_condition = var.cloud_monitoring_enabled == true && var.cloud_monitoring_instance_region == null && var.cloud_monitoring_access_key == null
  cloud_monitoring_key_validate_msg       = "Values for 'cloud_monitoring_access_key' and 'log_analysis_instance_region' variables must be passed when 'cloud_monitoring_enabled = true'"
  # tflint-ignore: terraform_unused_declarations
  cloud_monitoring_key_validate_check = regex("^${local.cloud_monitoring_key_validate_msg}$", (!local.cloud_monitoring_key_validate_condition ? local.cloud_monitoring_key_validate_msg : ""))
}

/** Log Analysis Configuration Start **/
resource "helm_release" "log_analysis_agent" {
  count            = var.log_analysis_enabled ? 1 : 0
  name             = var.log_analysis_agent_name
  chart            = local.log_analysis_chart_location
  namespace        = var.log_analysis_agent_namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true

  set {
    name  = "metadata.name"
    type  = "string"
    value = var.log_analysis_agent_name
  }
  set {
    name  = "image.version"
    type  = "string"
    value = local.log_analysis_image_tag_digest
  }
  set {
    name  = "image.registry"
    type  = "string"
    value = local.log_analysis_agent_registry
  }
  set {
    name  = "env.host"
    type  = "string"
    value = local.log_analysis_host
  }
  set {
    name  = "secret.name"
    type  = "string"
    value = var.log_analysis_secret_name
  }
  set_sensitive {
    name  = "secret.key"
    type  = "string"
    value = var.log_analysis_ingestion_key
  }
  set {
    name  = "agent.tags"
    type  = "string"
    value = join("\\,", local.log_analysis_agent_tags)
  }
  set {
    name  = "agent.dbPath"
    type  = "string"
    value = local.log_analysis_agent_db_path
  }

  values = [
    yamlencode({
      tolerations = var.log_analysis_agent_tolerations
    })
  ]

  dynamic "set" {
    for_each = var.log_analysis_agent_custom_line_inclusion != null ? [var.log_analysis_agent_custom_line_inclusion] : []
    content {
      name  = "agentMetadataLineInclusion"
      type  = "string"
      value = set.value
    }
  }

  dynamic "set" {
    for_each = var.log_analysis_agent_custom_line_exclusion != null ? [var.log_analysis_agent_custom_line_exclusion] : []
    content {
      name  = "agentMetadataLineExclusion"
      type  = "string"
      value = set.value
    }
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh ${var.log_analysis_agent_name} ${var.log_analysis_agent_namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
/** Log Analysis Configuration End **/

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

  set {
    name  = "metadata.name"
    type  = "string"
    value = var.cloud_monitoring_agent_name
  }
  set {
    name  = "image.version"
    type  = "string"
    value = local.cloud_monitoring_image_tag_digest
  }
  set {
    name  = "image.registry"
    type  = "string"
    value = local.cloud_monitoring_agent_registry
  }
  set {
    name  = "config.clustername"
    type  = "string"
    value = local.cluster_name
  }
  set {
    name  = "config.host"
    type  = "string"
    value = local.cloud_monitoring_host
  }
  set {
    name  = "secret.name"
    type  = "string"
    value = var.cloud_monitoring_secret_name
  }
  set_sensitive {
    name  = "secret.key"
    type  = "string"
    value = var.cloud_monitoring_access_key
  }
  set {
    name  = "config.tags"
    type  = "string"
    value = join("\\,", local.cloud_monitoring_agent_tags)
  }

  values = [yamlencode({
    metrics_filter = var.cloud_monitoring_metrics_filter
    }), yamlencode({
    tolerations = var.cloud_monitoring_agent_tolerations
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
module "logs_agents" {
  count                                  = var.logs_agent_enabled ? 1 : 0
  source                                 = "./modules/logs-agent-module"
  cluster_id                             = var.cluster_id
  cluster_resource_group_id              = var.cluster_resource_group_id
  cluster_config_endpoint_type           = var.cluster_config_endpoint_type
  logs_agent_name                        = var.logs_agent_name
  logs_agent_namespace                   = var.logs_agent_namespace
  logs_agent_trusted_profile             = var.logs_agent_trusted_profile
  logs_agent_iam_api_key                 = var.logs_agent_iam_api_key
  logs_agent_agent_tolerations           = var.logs_agent_agent_tolerations
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
}
/** Logs Agent Configuration End **/
