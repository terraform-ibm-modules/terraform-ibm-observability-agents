locals {
  logs_agent_image_tag_digest          = "1.3.0"
  logs_agent_selected_log_source_paths = distinct(concat([for namespace in var.logs_agent_log_source_namespaces : "/var/log/containers/*_${namespace}_*.log"], var.logs_agent_selected_log_source_paths))
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
  logs_agent_chart_location   = "oci://icr.io/ibm/observe/logs-agent-helm"
  logs_agent_iam_api_key      = var.logs_agent_iam_api_key != null ? var.logs_agent_iam_api_key : ""
  logs_agent_trusted_profile  = var.logs_agent_trusted_profile != null ? var.logs_agent_trusted_profile : ""
  cloud_logs_ingress_endpoint = var.cloud_logs_ingress_endpoint != null ? var.cloud_logs_ingress_endpoint : ""
  # tflint-ignore: terraform_unused_declarations
  validate_iam_mode = var.logs_agent_enabled == true && (var.logs_agent_iam_mode == "IAMAPIKey" && (var.logs_agent_iam_api_key == null || var.logs_agent_iam_api_key == "")) ? tobool("When passing 'IAMAPIKey' value for 'logs_agent_iam_mode' you cannot set 'logs_agent_ingestion_key' as null or empty string.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_trusted_profile_mode = var.logs_agent_enabled == true && (var.logs_agent_iam_mode == "TrustedProfile" && (var.logs_agent_trusted_profile == null || var.logs_agent_trusted_profile == "")) ? tobool(" When passing 'TrustedProfile' value for 'logs_agent_iam_mode' you cannot set 'logs_agent_trusted_profile' as null or empty string.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_direct_to_icl = var.logs_agent_enabled == true && (var.logs_agent_enable_direct_to_cloud_logs && (var.cloud_logs_ingress_endpoint == null || var.cloud_logs_ingress_endpoint == "")) ? tobool(" When 'logs_agent_enable_direct_to_cloud_logs' is enabled, you cannot set 'cloud_logs_ingress_endpoint' as null or empty string.") : true
}

resource "helm_release" "logs_agent" {
  count            = var.logs_agent_enabled ? 1 : 0
  name             = var.logs_agent_name
  chart            = local.logs_agent_chart_location
  namespace        = var.logs_agent_namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true

  set {
    name  = "metadata.name"
    type  = "string"
    value = var.logs_agent_name
  }
  set {
    name  = "image.version"
    type  = "string"
    value = local.logs_agent_image_tag_digest
  }
  set {
    name  = "env.ingestionHost"
    type  = "string"
    value = local.cloud_logs_ingress_endpoint
  }
  set {
    name  = "env.ingestionPort"
    value = var.cloud_logs_ingress_port
  }
  set_sensitive {
    name  = "secret.iamAPIKey"
    type  = "string"
    value = local.logs_agent_iam_api_key
  }
  set {
    name  = "env.trustedProfileID"
    type  = "string"
    value = local.logs_agent_trusted_profile
  }
  set {
    name  = "env.iamMode"
    type  = "string"
    value = var.logs_agent_iam_mode
  }
  set {
    name  = "env.iamEnvironment"
    type  = "string"
    value = var.logs_agent_iam_environment
  }
  set {
    name  = "additionalLogSourcePaths"
    type  = "string"
    value = join("\\,", var.logs_agent_additional_log_source_paths)
  }
  set {
    name  = "excludeLogSourcePaths"
    type  = "string"
    value = join("\\,", var.logs_agent_exclude_log_source_paths)
  }
  set {
    name  = "selectedLogSourcePaths"
    type  = "string"
    value = join("\\,", local.logs_agent_selected_log_source_paths)
  }
  set {
    name  = "clusterName"
    type  = "string"
    value = data.ibm_container_vpc_cluster.cluster.name
  }
  set {
    name  = "scc.create"
    value = var.logs_agent_enable_scc
  }

  # dummy value hack to force update https://github.com/hashicorp/terraform-provider-helm/issues/515#issuecomment-813088122
  values = [
    yamlencode({
      tolerations         = var.logs_agent_agent_tolerations
      additional_metadata = var.logs_agent_additional_metadata
      dummy               = uuid()
    })
  ]


  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh ${var.logs_agent_name} ${var.logs_agent_namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
