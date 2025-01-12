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
  cloud_monitoring_image_tag_digest = "13.7.1@sha256:7594347727a76fab1b6759575d84389ac1788bff6782046b330c730d67db790c" # datasource: icr.io/ext/sysdig/agent
  cloud_monitoring_agent_registry   = "icr.io/ext/sysdig/agent"
  cloud_monitoring_agent_tags       = var.cloud_monitoring_add_cluster_name ? concat(["ibm.containers-kubernetes.cluster.name:${local.cluster_name}"], var.cloud_monitoring_agent_tags) : var.cloud_monitoring_agent_tags
  cloud_monitoring_host             = var.cloud_monitoring_enabled ? var.cloud_monitoring_endpoint_type == "private" ? "ingest.private.${var.cloud_monitoring_instance_region}.monitoring.cloud.ibm.com" : "logs.${var.cloud_monitoring_instance_region}.monitoring.cloud.ibm.com" : null

  # TODO: Move this into variable.tf since module requires 1.9 now
  # VARIABLE VALIDATION
  cloud_monitoring_key_validate_condition = var.cloud_monitoring_enabled == true && var.cloud_monitoring_instance_region == null && var.cloud_monitoring_access_key == null
  cloud_monitoring_key_validate_msg       = "Values for 'cloud_monitoring_access_key' and 'log_analysis_instance_region' variables must be passed when 'cloud_monitoring_enabled = true'"
  # tflint-ignore: terraform_unused_declarations
  cloud_monitoring_key_validate_check = regex("^${local.cloud_monitoring_key_validate_msg}$", (!local.cloud_monitoring_key_validate_condition ? local.cloud_monitoring_key_validate_msg : ""))
  # Logs Agent Validation
  # tflint-ignore: terraform_unused_declarations
  validate_iam_mode = var.logs_agent_enabled == true && (var.logs_agent_iam_mode == "IAMAPIKey" && (var.logs_agent_iam_api_key == null || var.logs_agent_iam_api_key == "")) ? tobool("When passing 'IAMAPIKey' value for 'logs_agent_iam_mode' you cannot set 'logs_agent_iam_api_key' as null or empty string.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_trusted_profile_mode = var.logs_agent_enabled == true && (var.logs_agent_iam_mode == "TrustedProfile" && (var.logs_agent_trusted_profile == null || var.logs_agent_trusted_profile == "")) ? tobool(" When passing 'TrustedProfile' value for 'logs_agent_iam_mode' you cannot set 'logs_agent_trusted_profile' as null or empty string.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_icl_ingress_endpoint = var.logs_agent_enabled == true && (var.cloud_logs_ingress_endpoint == null || var.cloud_logs_ingress_endpoint == "") ? tobool("When 'logs_agent_enabled' is enabled, you cannot set 'cloud_logs_ingress_endpoint' as null or empty string.") : true
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
