##############################################################################
# Observability Agents
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].name : data.ibm_container_cluster.cluster[0].name
  resource_group_id = var.cluster_resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null
}

module "observability_agents" {
  source                       = "../.."
  cluster_id                   = var.cluster_id
  cluster_resource_group_id    = var.cluster_resource_group_id
  cluster_config_endpoint_type = var.cluster_config_endpoint_type
  # Cloud Monitoring (Sysdig) Agent
  cloud_monitoring_enabled           = var.cloud_monitoring_enabled
  cloud_monitoring_agent_name        = var.prefix != null ? "${var.prefix}-${var.cloud_monitoring_agent_name}" : var.cloud_monitoring_agent_name
  cloud_monitoring_agent_namespace   = var.cloud_monitoring_agent_namespace
  cloud_monitoring_endpoint_type     = var.cloud_monitoring_endpoint_type
  cloud_monitoring_access_key        = var.cloud_monitoring_access_key
  cloud_monitoring_secret_name       = var.prefix != null ? "${var.prefix}-${var.cloud_monitoring_secret_name}" : var.cloud_monitoring_secret_name
  cloud_monitoring_metrics_filter    = var.cloud_monitoring_metrics_filter
  cloud_monitoring_agent_tags        = var.cloud_monitoring_agent_tags
  cloud_monitoring_instance_region   = var.cloud_monitoring_instance_region
  cloud_monitoring_agent_tolerations = var.cloud_monitoring_agent_tolerations
  cloud_monitoring_add_cluster_name  = var.cloud_monitoring_add_cluster_name
  # Logs Agent
  logs_agent_enabled                     = var.logs_agent_enabled
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
}
