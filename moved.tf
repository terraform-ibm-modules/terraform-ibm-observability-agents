# The following moved blocks allow consumers to upgrade from v2 of the module without instances being destroyed

moved {
  from = module.observability_agents.helm_release.logdna_agent[0]
  to   = module.observability_agents.helm_release.log_analysis_agent[0]
}

moved {
  from = module.observability_agents.helm_release.sysdig_agent[0]
  to   = module.observability_agents.helm_release.cloud_monitoring_agent[0]
}

moved {
  from = module.observability_agents.data.ibm_resource_instance.logdna_instance[0]
  to   = module.observability_agents.data.ibm_resource_instance.log_analysis_instance[0]
}

moved {
  from = module.observability_agents.data.ibm_resource_instance.sysdig_instance[0]
  to   = module.observability_agents.data.ibm_resource_instance.cloud_monitoring_instance[0]
}
