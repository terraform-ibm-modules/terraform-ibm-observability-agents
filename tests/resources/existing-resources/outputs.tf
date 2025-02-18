##############################################################################
# Outputs
##############################################################################

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.resource_group_name
}

output "prefix" {
  description = "Prefix"
  value       = var.prefix
}

output "cos_crn" {
  description = "COS CRN"
  value       = module.cos.cos_instance_crn
}

output "bucket_name" {
  description = "Log Archive bucket name"
  value       = module.cos.bucket_name
}

output "bucket_name_at" {
  description = "Activity Tracker bucket name"
  value       = module.additional_cos_bucket.bucket_name
}

output "bucket_endpoint" {
  description = "Log Archive bucket endpoint"
  value       = module.cos.s3_endpoint_public
}

output "bucket_endpoint_at" {
  description = "Activity Tracker bucket endpoint"
  value       = module.additional_cos_bucket.s3_endpoint_public
}

output "data_bucket_crn" {
  description = "Cloud Logs data bucket CRN"
  value       = module.cloud_log_buckets.buckets["${var.prefix}-data-bucket"].bucket_crn
}

output "data_bucket_endpoint" {
  description = "Cloud Logs data bucket endpoint"
  value       = module.cloud_log_buckets.buckets["${var.prefix}-data-bucket"].s3_endpoint_public
}

output "metrics_bucket_crn" {
  description = "Cloud Logs metrics bucket CRN"
  value       = module.cloud_log_buckets.buckets["${var.prefix}-metrics-bucket"].bucket_crn
}

output "metrics_bucket_endpoint" {
  description = "Cloud Logs metrics bucket endpoint"
  value       = module.cloud_log_buckets.buckets["${var.prefix}-metrics-bucket"].s3_endpoint_public
}

output "en_crn_1" {
  description = "Event Notification CRN"
  value       = module.event_notification_1.crn
}

output "en_crn_2" {
  description = "Event Notification CRN"
  value       = module.event_notification_2.crn
}

output "cloud_monitoring_crn" {
  description = "Cloud Monitoring CRN"
  value       = module.cloud_monitoring.crn
}
