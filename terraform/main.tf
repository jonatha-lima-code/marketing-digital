
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
}

resource "aws_s3_bucket" "processed" {
  bucket = var.s3_bucket_processed
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
  publicly_accessible = true 
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


# IAM Role para Lambda
resource "aws_iam_role" "lambda_redshift_role" {
  name = "lambda_redshift_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_redshift_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_redshift_access" {
  role       = aws_iam_role.lambda_redshift_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}

# Lambda Function
resource "aws_lambda_function" "load_to_redshift" {
  function_name = "load_to_redshift"
  role          = aws_iam_role.lambda_redshift_role.arn
  handler       = "load_to_redshift.lambda_handler"
  runtime       = "python3.12"

  filename         = "${path.module}/../lambda/load_to_redshift.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/load_to_redshift.zip")

  environment {
    variables = {
      REDSHIFT_HOST        = var.redshift_host
      REDSHIFT_DB          = var.redshift_db
      REDSHIFT_USER        = var.redshift_user
      REDSHIFT_PASS        = var.redshift_pass
      IAM_ROLE_ARN         = var.redshift_iam_role
      S3_BUCKET_PROCESSED  = var.s3_bucket_processed
      S3_PREFIX            = var.s3_prefix
    }
  }
}

# Evento S3 -> Lambda
resource "aws_s3_bucket_notification" "trigger_lambda" {
  bucket = var.s3_bucket_processed

  lambda_function {
    lambda_function_arn = aws_lambda_function.load_to_redshift.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.s3_prefix
  }

  depends_on = [aws_lambda_function.load_to_redshift]
}

# Permitir S3 chamar a Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.load_to_redshift.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.s3_bucket_processed}"
}


output "lambda_redshift_role_arn" {
  value = aws_iam_role.lambda_redshift_role.arn
}

# Permissões S3 para o Glue
resource "aws_iam_role_policy" "glue_s3_access" {
  name = "glue-s3-access"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket}",
          "arn:aws:s3:::${var.s3_bucket}/*",
          "arn:aws:s3:::${var.s3_bucket_processed}",
          "arn:aws:s3:::${var.s3_bucket_processed}/*"
        ]
      }
    ]
  })
}
