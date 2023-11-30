##############################################################################
# observability-agents-module
#
##############################################################################

data "ibm_container_vpc_cluster" "cluster" {
  name              = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null value represents default
}

##############################################################################
# NOTE ABOUT DATA INSTANCE LOOKUP
# Since data resource lookups are performed always, including plan phase,
# there were situations where these calls errored out during initial plan
# before resources exist. This was due to the NAME attribute of the instances
# NOT being generated values (known after apply).
# Adding a "depends_on" to each block to make them depend on their appropriate
# access/ingestion key values, since those are generated and forces data lookup
# to be delayed until resources are applied.
##############################################################################
data "ibm_resource_instance" "log_analysis_instance" {
  count             = var.log_analysis_enabled ? 1 : 0
  name              = var.log_analysis_instance_name
  resource_group_id = local.log_analysis_resource_group_id
  service           = "logdna"
  depends_on        = [var.log_analysis_ingestion_key] # see NOTE above
}

data "ibm_resource_instance" "cloud_monitoring_instance" {
  count             = var.cloud_monitoring_enabled ? 1 : 0
  name              = var.cloud_monitoring_instance_name
  resource_group_id = local.cloud_monitoring_resource_group_id
  service           = "sysdig-monitor"
  depends_on        = [var.cloud_monitoring_access_key] # see NOTE above
}

locals {
  log_analysis_secret_name = "log-analysis-agent" #checkov:skip=CKV_SECRET_6
  # Not publically documented in provider. See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4485
  cluster_name                        = data.ibm_container_vpc_cluster.cluster.resource_name
  log_analysis_chart_location         = "${path.module}/chart/log-analysis-agent"
  log_analysis_resource_group_id      = var.log_analysis_resource_group_id != null ? var.log_analysis_resource_group_id : var.cluster_resource_group_id
  log_analysis_agent_namespace        = "ibm-observe"
  log_analysis_agent_registry         = "icr.io/ext/logdna-agent"
  log_analysis_key_validate_condition = var.log_analysis_enabled == true && var.log_analysis_ingestion_key == null
  log_analysis_key_validate_msg       = "Values for 'log_analysis_ingestion_key' variables must be passed when 'log_analysis_enabled = true'"
  # tflint-ignore: terraform_unused_declarations
  log_analysis_key_validate_check         = regex("^${local.log_analysis_key_validate_msg}$", (!local.log_analysis_key_validate_condition ? local.log_analysis_key_validate_msg : ""))
  log_analysis_agent_tags                 = var.log_analysis_add_cluster_name ? concat([local.cluster_name], var.log_analysis_agent_tags) : var.log_analysis_agent_tags
  cloud_monitoring_chart_location         = "${path.module}/chart/cloud-monitoring-agent"
  cloud_monitoring_resource_group_id      = var.cloud_monitoring_resource_group_id != null ? var.cloud_monitoring_resource_group_id : var.cluster_resource_group_id
  cloud_monitoring_agent_registry         = "icr.io/ext/sysdig/agent"
  cloud_monitoring_agent_namespace        = "ibm-observe"
  cloud_monitoring_key_validate_condition = var.cloud_monitoring_enabled == true && var.cloud_monitoring_access_key == null
  cloud_monitoring_key_validate_msg       = "Values for 'cloud_monitoring_access_key' variables must be passed when 'cloud_monitoring_enabled = true'"
  # tflint-ignore: terraform_unused_declarations
  cloud_monitoring_key_validate_check = regex("^${local.cloud_monitoring_key_validate_msg}$", (!local.cloud_monitoring_key_validate_condition ? local.cloud_monitoring_key_validate_msg : ""))
  cloud_monitoring_agent_tags         = var.cloud_monitoring_add_cluster_name ? concat([local.cluster_name], var.cloud_monitoring_agent_tags) : var.cloud_monitoring_agent_tags
}

/** Log Analysis Configuration Start **/

resource "helm_release" "log_analysis_agent" {
  count            = var.log_analysis_enabled ? 1 : 0
  name             = "log-analysis-agent"
  chart            = local.log_analysis_chart_location
  namespace        = local.log_analysis_agent_namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true

  set {
    name  = "image.version"
    type  = "string"
    value = var.log_analysis_agent_version
  }
  set {
    name  = "image.registry"
    type  = "string"
    value = local.log_analysis_agent_registry
  }
  set {
    name  = "env.region"
    type  = "string"
    value = data.ibm_resource_instance.log_analysis_instance[0].location
  }
  set {
    name  = "secret.name"
    type  = "string"
    value = local.log_analysis_secret_name
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
    command     = "${path.module}/scripts/confirm-rollout-status.sh log-analysis-agent ${local.log_analysis_agent_namespace}"
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

  name             = "cloud-monitoring-agent"
  chart            = local.cloud_monitoring_chart_location
  namespace        = local.cloud_monitoring_agent_namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true
  reset_values     = true

  set {
    name  = "image.version"
    type  = "string"
    value = var.cloud_monitoring_agent_version
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
    name  = "config.region"
    type  = "string"
    value = data.ibm_resource_instance.cloud_monitoring_instance[0].location
  }
  set_sensitive {
    name  = "secret.key"
    type  = "string"
    value = var.cloud_monitoring_access_key
  }

  set {
    name  = "agent.tags"
    type  = "string"
    value = join("\\,", local.cloud_monitoring_agent_tags)
  }

  values = [yamlencode({
    metrics_filter = var.cloud_monitoring_metrics_filter
  })]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh cloud-monitoring-agent ${local.cloud_monitoring_agent_namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

/** Cloud Monitoring Configuration End **/
