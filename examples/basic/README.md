# Log Analysis agent

## Deprecated: Log Analysis

**Important:** IBM Log Analysis will be discontinued on 30 March 2025 and replaced by IBM Cloud Logs.

An end-to-end example that uses the module's default variable values.

The example sets up the logging agent for [Kubernetes metadata filtering](https://github.com/logdna/logdna-agent-v2/blob/3.8/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering).

The example configures the agent to include all log lines coming from the `default` Kubernetes namespace and excludes anything with a label `app.kubernetes.io/name` and value `sample-app` or an annotation `annotation.user` with the value `sample-user`.

:exclamation: The service IBM Cloud Log Analysis is now deprecated and new instances cannot be provisioned after November 30, 2024, and all existing instances will be destroyed on March 30, 2025. For more information, see https://cloud.ibm.com/docs/log-analysis?topic=log-analysis-getting-started
