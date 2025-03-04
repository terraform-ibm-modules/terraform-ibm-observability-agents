# Configuring Cloud Monitoring Metrics Filter

When you deploy the IBM Cloud Monitoring agent using the `solutions/fully-configurable` module, you can configure the metrics that the agent collects by using the `cloud_monitoring_metrics_filter` variable. This variable allows you to specify which metrics to include or exclude from the collection.

### Options for `cloud_monitoring_metrics_filter`
- `type` (required): The type of filter to apply. Valid values are `include` and `exclude`.
- `name` (required): The name of the metric to include or exclude. You can use wildcards to match multiple metrics.

### Example `cloud_monitoring_metrics_filter` Usage

To include specific metrics and exclude others, you can configure the `cloud_monitoring_metrics_filter` variable as follows:

```hcl
cloud_monitoring_metrics_filter = [
  {
    type = "include"
    name = "metricA.*"
  },
  {
    type = "exclude"
    name = "metricB.*"
  }
]
```

In this example:
- All metrics that match the pattern `metricA.*` will be included.
- All metrics that match the pattern `metricB.*` will be excluded.

### What It Does

The `cloud_monitoring_metrics_filter` variable is used to configure the Cloud Monitoring agent to include or exclude specific metrics during the collection process. This configuration is passed down to the base module, which applies the filter settings to the agent.
