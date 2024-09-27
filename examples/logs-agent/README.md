# Cloud Logs agent using VPE ingress endpoint with a Trusted Profile

An example that shows how to deploy Logs Routing agents in an Red Hat OpenShift container platform or Kubernetes cluster to send Logs directly to IBM Cloud Logs.

The example provisions the following resources:

- A new resource group, if an existing one is not passed in.
- A basic VPC.
- An IBM Cloud Object Storage instance.
- A Red Hat OpenShift Container Platform VPC cluster or a Kubernetes cluster.
- A Trusted Profile.
- An IBM Cloud Logs instance
- A Virtual Private Endpoint for Cloud Logs.
- Logs agents.
