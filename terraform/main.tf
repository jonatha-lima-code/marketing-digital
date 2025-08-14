
provider "aws" {
  region = var.region
}

resource "aws_kinesis_stream" "marketing_events" {
  name             = var.kinesis_name
  shard_count      = 1
  retention_period = 24
}

resource "aws_s3_bucket" "glue_staging" {
  bucket = var.s3_bucket
  acl    = "private"
}

resource "aws_iam_role" "glue_role" {
  name = "glue-role-marketing-poc"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_policy.json
}

data "aws_iam_policy_document" "glue_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "glue_attached" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_redshiftserverless_namespace" "ns" {
  namespace_name    = var.rs_namespace
  admin_username    = var.rs_admin_user
  admin_user_password = var.rs_admin_password
}

resource "aws_redshiftserverless_workgroup" "wg" {
  workgroup_name = var.rs_workgroup
  namespace_name = aws_redshiftserverless_namespace.ns.namespace_name
  base_capacity  = var.rs_capacity
}

output "kinesis_stream_name" {
  value = aws_kinesis_stream.marketing_events.name
}

output "s3_bucket" {
  value = aws_s3_bucket.glue_staging.bucket
}

output "redshift_endpoint" {
  value = aws_redshiftserverless_workgroup.wg.endpoint
}
