##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Create Cloud Object Storage instance and buckets
##############################################################################

module "cos" {
  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "8.16.4"
  resource_group_id      = module.resource_group.resource_group_id
  region                 = var.region
  cos_instance_name      = "${var.prefix}-cos"
  cos_tags               = var.resource_tags
  bucket_name            = "${var.prefix}-bucket"
  retention_enabled      = false # disable retention for test environments - enable for stage/prod
  kms_encryption_enabled = false
}

module "cloud_log_buckets" {
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "8.16.4"
  bucket_configs = [
    {
      bucket_name            = "${var.prefix}-data-bucket"
      add_bucket_name_suffix = true
      region_location        = var.region
      create_cos_instance    = false
      resource_instance_id   = module.cos.cos_instance_id
      kms_encryption_enabled = false
    },
    {
      bucket_name            = "${var.prefix}-metrics-bucket"
      add_bucket_name_suffix = true
      region_location        = var.region
      create_cos_instance    = false
      resource_instance_id   = module.cos.cos_instance_id
      kms_encryption_enabled = false
    }
  ]
}


module "cloud_monitoring" {
  source                  = "terraform-ibm-modules/observability-instances/ibm//modules/cloud_monitoring"
  version                 = "3.4.0"
  region                  = var.region
  resource_group_id       = module.resource_group.resource_group_id
  instance_name           = "${var.prefix}-sysdig"
  plan                    = "lite"
  tags                    = var.resource_tags
  enable_platform_metrics = false
}
