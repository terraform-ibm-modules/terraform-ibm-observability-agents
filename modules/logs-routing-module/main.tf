locals {
  logs_routing_agent_image_tag_digest    = "1.2.2"
  logs_routing_selected_log_source_paths = distinct(concat([for namespace in var.logs_routing_log_source_namespaces : "/var/log/containers/*_${namespace}_*.log"], var.logs_routing_selected_log_source_paths))
}
# Lookup cluster name from ID
data "ibm_container_vpc_cluster" "cluster" {
  name              = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
}

# Download cluster config which is required to connect to cluster
data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
  config_dir        = "${path.module}/kubeconfig"                                                             # See https://github.ibm.com/GoldenEye/issues/issues/552
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null represents default
}

locals {
  logs_routing_chart_location   = "../../chart/logs-routing-agent"
  logs_routing_host             = "ingester.private.${var.logs_routing_region}.logs-router.cloud.ibm.com"
  logs_routing_ingestion_key    = var.logs_routing_ingestion_key != null ? var.logs_routing_ingestion_key : ""
  logs_routing_trusted_profile  = var.logs_routing_trusted_profile != null ? var.logs_routing_trusted_profile : ""
  logs_routing_application_name = var.logs_routing_application_name != null ? var.logs_routing_application_name : ""
  logs_routing_subsystem_name   = var.logs_routing_subsystem_name != null ? var.logs_routing_subsystem_name : ""
  # tflint-ignore: terraform_unused_declarations
  validate_iam_mode = var.logs_routing_enabled == true && (var.logs_routing_iam_mode == "IAMAPIKey" && (var.logs_routing_ingestion_key == null || var.logs_routing_ingestion_key == "")) ? tobool("When passing 'IAMAPIKey' value for 'logs_routing_iam_mode' you cannot set 'logs_routing_ingestion_key' as null or empty string.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_trusted_profile_mode = var.logs_routing_enabled == true && (var.logs_routing_iam_mode == "TrustedProfile" && (var.logs_routing_trusted_profile == null || var.logs_routing_trusted_profile == "")) ? tobool(" When passing 'TrustedProfile' value for 'logs_routing_iam_mode' you cannot set 'logs_routing_trusted_profile' as null or empty string.") : true
}

resource "helm_release" "logs_routing_agent" {
  count            = var.logs_routing_enabled ? 1 : 0
  name             = var.logs_routing_agent_name
  chart            = local.logs_routing_chart_location
  namespace        = var.logs_routing_agent_namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true

  set {
    name  = "metadata.name"
    type  = "string"
    value = var.logs_routing_agent_name
  }
  set {
    name  = "image.version"
    type  = "string"
    value = local.logs_routing_agent_image_tag_digest
  }
  set {
    name  = "env.ingestionHost"
    type  = "string"
    value = local.logs_routing_host
  }
  set {
    name  = "env.ingestionPort"
    value = var.logs_routing_port
  }
  set_sensitive {
    name  = "secret.iamAPIKey"
    type  = "string"
    value = local.logs_routing_ingestion_key
  }
  set {
    name  = "env.trustedProfileID"
    type  = "string"
    value = local.logs_routing_trusted_profile
  }
  set {
    name  = "env.iamMode"
    type  = "string"
    value = var.logs_routing_iam_mode
  }
  set {
    name  = "env.iamEnvironment"
    type  = "string"
    value = var.logs_routing_iam_environment
  }
  set {
    name  = "additionalLogSourcePaths"
    type  = "string"
    value = join("\\,", var.logs_routing_additional_log_source_paths)
  }
  set {
    name  = "excludeLogSourcePaths"
    type  = "string"
    value = join("\\,", var.logs_routing_exclude_log_source_paths)
  }
  set {
    name  = "selectedLogSourcePaths"
    type  = "string"
    value = join("\\,", local.logs_routing_selected_log_source_paths)
  }
  set {
    name  = "cluster.name"
    type  = "string"
    value = data.ibm_container_vpc_cluster.cluster.name
  }
  set {
    name  = "scc.create"
    value = var.logs_routing_enable_scc
  }
  set {
    name  = "filterAddICLmetadata.applicationName"
    value = local.logs_routing_application_name
  }
  set {
    name  = "filterAddICLmetadata.subsystemName"
    value = local.logs_routing_subsystem_name
  }

  # dummy value hack to force update https://github.com/hashicorp/terraform-provider-helm/issues/515#issuecomment-813088122
  values = [
    yamlencode({
      tolerations         = var.logs_routing_agent_tolerations
      additional_metadata = var.logs_routing_additional_metadata
      dummy               = uuid()
    })
  ]


  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh ${var.logs_routing_agent_name} ${var.logs_routing_agent_namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
