resource "helm_release" "agent" {
  name             = var.name
  chart            = var.chart_location
  namespace        = var.namespace
  create_namespace = true
  timeout          = var.timeout
  wait             = var.wait
  recreate_pods    = var.recreate_pods
  force_update     = var.force_update
  reset_values     = var.reset_values

  # dummy value hack to force update https://github.com/hashicorp/terraform-provider-helm/issues/515#issuecomment-813088122
  values = [
    yamlencode({
      dummy : uuid()
    })
  ]

  dynamic "set" {
    for_each = var.values
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.region
  }

  dynamic "provisioner" {
    for_each = var.local_exec_commands
    content {
      local-exec {
        command     = provisioner.value.command
        interpreter = ["/bin/bash", "-c"]
        environment = provisioner.value.environment
      }
    }
  }
}
