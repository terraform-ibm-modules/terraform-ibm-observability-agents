# The following moved blocks allow consumers to upgrade without instances being destroyed

moved {
  from = helm_release.sysdig_agent[0]
  to   = helm_release.cloud_monitoring_agent[0]
}

moved {
  from = data.ibm_resource_instance.sysdig_instance[0]
  to   = data.ibm_resource_instance.cloud_monitoring_instance[0]
}
