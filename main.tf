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
data "ibm_resource_instance" "logdna_instance" {
  count             = var.logdna_enabled ? 1 : 0
  name              = var.logdna_instance_name
  resource_group_id = local.logdna_resource_group_id
  service           = "logdna"
  depends_on        = [var.logdna_ingestion_key] # see NOTE above
}

data "ibm_resource_instance" "sysdig_instance" {
  count             = var.sysdig_enabled ? 1 : 0
  name              = var.sysdig_instance_name
  resource_group_id = local.sysdig_resource_group_id
  service           = "sysdig-monitor"
  depends_on        = [var.sysdig_access_key] # see NOTE above
}

locals {
  logdna_secret_name = "logdna-agent" #checkov:skip=CKV_SECRET_6
  # Not publically documented in provider. See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4485
  cluster_name                  = data.ibm_container_vpc_cluster.cluster.resource_name
  logdna_chart_location         = "${path.module}/chart/logdna-agent"
  logdna_resource_group_id      = var.logdna_resource_group_id != null ? var.logdna_resource_group_id : var.cluster_resource_group_id
  logdna_agent_namespace        = "ibm-observe"
  logdna_agent_registry         = "icr.io/ext/logdna-agent"
  logdna_key_validate_condition = var.logdna_enabled == true && var.logdna_ingestion_key == null
  logdna_key_validate_msg       = "Values for 'logdna_ingestion_key' variables must be passed when 'logdna_enabled = true'"
  # tflint-ignore: terraform_unused_declarations
  logdna_key_validate_check     = regex("^${local.logdna_key_validate_msg}$", (!local.logdna_key_validate_condition ? local.logdna_key_validate_msg : ""))
  logdna_agent_tags             = var.logdna_add_cluster_name ? concat([local.cluster_name], var.logdna_agent_tags) : var.logdna_agent_tags
  sysdig_chart_location         = "${path.module}/chart/sysdig-agent"
  sysdig_resource_group_id      = var.sysdig_resource_group_id != null ? var.sysdig_resource_group_id : var.cluster_resource_group_id
  sysdig_agent_registry         = "icr.io/ext/sysdig/agent"
  sysdig_agent_namespace        = "ibm-observe"
  sysdig_key_validate_condition = var.sysdig_enabled == true && var.sysdig_access_key == null
  sysdig_key_validate_msg       = "Values for 'sysdig_access_key' variables must be passed when 'sysdig_enabled = true'"
  # tflint-ignore: terraform_unused_declarations
  sysdig_key_validate_check = regex("^${local.sysdig_key_validate_msg}$", (!local.sysdig_key_validate_condition ? local.sysdig_key_validate_msg : ""))
}

/** LogDNA Configuration Start **/

resource "helm_release" "logdna_agent" {
  count            = var.logdna_enabled ? 1 : 0
  name             = "logdna-agent"
  chart            = local.logdna_chart_location
  namespace        = local.logdna_agent_namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true

  set {
    name  = "image.version"
    type  = "string"
    value = var.logdna_agent_version
  }
  set {
    name  = "image.registry"
    type  = "string"
    value = local.logdna_agent_registry
  }
  set {
    name  = "env.region"
    type  = "string"
    value = data.ibm_resource_instance.logdna_instance[0].location
  }
  set {
    name  = "secret.name"
    type  = "string"
    value = local.logdna_secret_name
  }
  set_sensitive {
    name  = "secret.key"
    type  = "string"
    value = var.logdna_ingestion_key
  }
  set {
    name  = "agent.tags"
    type  = "string"
    value = join("\\,", local.logdna_agent_tags)
  }

  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh logdna-agent ${local.logdna_agent_namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

/** LogDNA Configuration End **/

/** Sysdig Configuration Start **/
resource "helm_release" "sysdig_agent" {
  count = var.sysdig_enabled ? 1 : 0

  name             = "sysdig-agent"
  chart            = local.sysdig_chart_location
  namespace        = local.sysdig_agent_namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true
  reset_values     = true

  set {
    name  = "image.version"
    type  = "string"
    value = var.sysdig_agent_version
  }
  set {
    name  = "image.registry"
    type  = "string"
    value = local.sysdig_agent_registry
  }
  set {
    name  = "config.clustername"
    type  = "string"
    value = local.cluster_name
  }
  set {
    name  = "config.region"
    type  = "string"
    value = data.ibm_resource_instance.sysdig_instance[0].location
  }
  set_sensitive {
    name  = "secret.key"
    type  = "string"
    value = var.sysdig_access_key
  }

  values = [yamlencode({
    metrics_filter = var.sysdig_metrics_filter
  })]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh sysdig-agent ${local.sysdig_agent_namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}

/** Sysdig Configuration End **/
