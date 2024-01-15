##############################################################################
# terraform-ibm-observability-agents
##############################################################################

# Lookup cluster name from ID
data "ibm_container_vpc_cluster" "cluster" {
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
  cluster_name                  = data.ibm_container_vpc_cluster.cluster.resource_name # Not publically documented in provider. See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4485
  log_analysis_chart_location   = "${path.module}/chart/logdna-agent"
  log_analysis_image_tag_digest = "3.9.1-20231225.fb0af936e8df898f@sha256:3d572353ca69c8d0817ba0c9cb80ef269f4e6f524cee3c98ffe18ef9420b253f" # datasource: icr.io/ext/logdna-agent
  log_analysis_agent_registry   = "icr.io/ext/logdna-agent"
  log_analysis_agent_tags       = var.log_analysis_add_cluster_name ? concat([local.cluster_name], var.log_analysis_agent_tags) : var.log_analysis_agent_tags
  log_analysis_host             = var.log_analysis_endpoint_type == "private" ? "logs.private.${var.log_analysis_instance_region}.logging.cloud.ibm.com" : "logs.${var.log_analysis_instance_region}.logging.cloud.ibm.com"
  # The directory in which the logdna agent will store its state database.
  # Note that the agent must have write access to the directory and be a persistent volume.
  log_analysis_agent_db_path        = "/var/lib/logdna"
  cloud_monitoring_chart_location   = "${path.module}/chart/sysdig-agent"
  cloud_monitoring_image_tag_digest = "12.19.0@sha256:5ab96c580f2cc33bf55afcb9889e9195a70b80e83909d861f020eec461239fad" # datasource: icr.io/ext/sysdig/agent
  cloud_monitoring_agent_registry   = "icr.io/ext/sysdig/agent"
  cloud_monitoring_agent_tags       = var.cloud_monitoring_add_cluster_name ? concat(["ibm.containers-kubernetes.cluster.name:${local.cluster_name}"], var.cloud_monitoring_agent_tags) : var.cloud_monitoring_agent_tags
  cloud_monitoring_host             = var.cloud_monitoring_endpoint_type == "private" ? "ingest.private.${var.cloud_monitoring_instance_region}.monitoring.cloud.ibm.com" : "logs.${var.cloud_monitoring_instance_region}.monitoring.cloud.ibm.com"

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
