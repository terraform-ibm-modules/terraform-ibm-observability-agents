# Monitoring agent + Cloud Logs agent on Kubernetes using CSE ingress endpoint with an apikey

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=observability-agents-obs-agent-iks-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents/tree/main/examples/obs-agent-iks"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


An example that shows how to deploy Logs agents and Monitoring agent in a Kubernetes cluster to send Logs directly to IBM Cloud Logs and Cloud Monitoring instance respectively.

The example provisions the following resources:
- A new resource group, if an existing one is not passed in.
- A basic VPC (if `is_vpc_cluster` is true).
- A Kubernetes cluster.
- A Service ID with `Sender` role to `logs` service and an apikey.
- An IBM Cloud Logs and Cloud Monitoring instance
- Logs agents and Monitoring agent

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
