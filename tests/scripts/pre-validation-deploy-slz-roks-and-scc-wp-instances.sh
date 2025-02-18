#! /bin/bash

############################################################################################################
## This script is used by the catalog pipeline to deploy the SLZ ROKS and Observability instances,
## which are the prerequisites for the Observability Agents extension.
############################################################################################################

set -e

DA_DIR="solutions/standard"
TERRAFORM_SOURCE_DIR="tests/resources"
JSON_FILE="${DA_DIR}/catalogValidationValues.json"
REGION="us-south"
TF_VARS_FILE="terraform.tfvars"

(
  cwd=$(pwd)
  cd ${TERRAFORM_SOURCE_DIR}
  echo "Provisioning prerequisite SLZ ROKS CLUSTER and Observability Instances .."
  terraform init || exit 1
  # $VALIDATION_APIKEY is available in the catalog runtime
  {
    echo "ibmcloud_api_key=\"${VALIDATION_APIKEY}\""
    echo "region=\"${REGION}\""
    echo "prefix=\"slz-$(openssl rand -hex 2)\""
  } >> ${TF_VARS_FILE}
  terraform apply -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1

  region_var_name="region"
  cluster_id_var_name="cluster_id"
  cluster_id_value=$(terraform output -state=terraform.tfstate -raw workload_cluster_id)
  cluster_resource_group_id_var_name="cluster_resource_group_id"
  cluster_resource_group_id_value=$(terraform output -state=terraform.tfstate -raw cluster_resource_group_id)
  cloud_monitoring_instance_region_var_name="cloud_monitoring_instance_region"
  cloud_monitoring_access_key_var_name="cloud_monitoring_access_key"
  cloud_monitoring_access_key_value=$(terraform output -state=terraform.tfstate -raw cloud_monitoring_access_key)
  logs_agent_trusted_profile_var_name="logs_agent_trusted_profile"
  logs_agent_trusted_profile_value=$(terraform output -state=terraform.tfstate -raw trusted_profile_id)
  cloud_logs_ingress_endpoint_var_name="cloud_logs_ingress_endpoint"
  cloud_logs_ingress_endpoint_value=$(terraform output -state=terraform.tfstate -raw cloud_logs_ingress_private_endpoint)

  echo "Appending '${cluster_id_var_name}' and '${region_var_name}' input variable values to ${JSON_FILE}.."

  cd "${cwd}"
  jq -r --arg region_var_name "${region_var_name}" \
        --arg region_var_value "${REGION}" \
        --arg cluster_id_var_name "${cluster_id_var_name}" \
        --arg cluster_id_value "${cluster_id_value}" \
        --arg cluster_resource_group_id_var_name "${cluster_resource_group_id_var_name}" \
        --arg cluster_resource_group_id_value "${cluster_resource_group_id_value}" \
        --arg cloud_monitoring_access_key_var_name "${cloud_monitoring_access_key_var_name}" \
        --arg cloud_monitoring_access_key_value "${cloud_monitoring_access_key_value}" \
        --arg cloud_monitoring_instance_region_var_name "${cloud_monitoring_instance_region_var_name}" \
        --arg cloud_monitoring_instance_region_var_value "${REGION}" \
        --arg logs_agent_trusted_profile_var_name "${logs_agent_trusted_profile_var_name}" \
        --arg logs_agent_trusted_profile_value "${logs_agent_trusted_profile_value}" \
        --arg cloud_logs_ingress_endpoint_var_name "${cloud_logs_ingress_endpoint_var_name}" \
        --arg cloud_logs_ingress_endpoint_value "${cloud_logs_ingress_endpoint_value}" \
        '. + {($region_var_name): $region_var_value, ($cluster_id_var_name): $cluster_id_value, ($cluster_resource_group_id_var_name): $cluster_resource_group_id_value, ($cloud_monitoring_instance_region_var_name): $cloud_monitoring_instance_region_var_value, ($cloud_monitoring_access_key_var_name): $cloud_monitoring_access_key_value, ($logs_agent_trusted_profile_var_name): $logs_agent_trusted_profile_value, ($cloud_logs_ingress_endpoint_var_name): $cloud_logs_ingress_endpoint_value}' "${JSON_FILE}" > tmpfile && mv tmpfile "${JSON_FILE}" || exit 1

  echo "Pre-validation complete successfully"
)