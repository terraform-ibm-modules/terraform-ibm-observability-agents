# Deploy basic observability agents

An end-to-end example that uses the module's default variable values.

The example sets up the logging agent for [Kubernetes metadata filtering](https://github.com/logdna/logdna-agent-v2/blob/3.8/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering).

The example configures the agent to include all log lines coming from the `default` Kubernetes namespace and excludes anything with a label `app.kubernetes.io/name` and value `sample-app` or an annotation `annotation.user` with the value `sample-user`.
