# Monitoring agent + Cloud Logs agent on OCP using VPE ingress endpoint with a Trusted Profile

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=observability-agents-obs-agent-ocp-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-observability-agents/tree/main/examples/obs-agent-ocp"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


An example that shows how to deploy Logs Routing agents and Monitoring agent in an Red Hat OpenShift container platform cluster to send Logs directly to IBM Cloud Logs and Cloud Monitoring instance respectively.

The example provisions the following resources:

- A new resource group, if an existing one is not passed in.
- A basic VPC.
- A Red Hat OpenShift Container Platform VPC cluster.
- A Trusted Profile with `Sender` role to `logs` service.
- An IBM Cloud Logs and Cloud Monitoring instance.
- A Virtual Private Endpoint for Cloud Logs.
- Logs agents and Monitoring agent

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
