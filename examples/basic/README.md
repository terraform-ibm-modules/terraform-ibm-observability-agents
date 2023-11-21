# Deploy basic observability agents

An end to end example using the module's default variable values.

The example shows how to configure the module to setup the Logging agent for [Kubernetes metadata logs filtering](https://github.com/logdna/logdna-agent-v2/blob/3.8/docs/KUBERNETES.md#configuration-for-kubernetes-metadata-filtering) in order to:

- include all log lines coming from the "default" Kubernetes namespace
- exclude anything with a label `app.kubernetes.io/name` with value `sample-app` or an annotation `annotation.user` with value `sample-user`
