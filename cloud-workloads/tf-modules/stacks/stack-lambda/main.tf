# A Lambda function, fronted by the API Gateway stack.
#
# Written as plain resources rather than wrapped in a community module: the
# wrapper's main value is packaging the deployment artefact, and here CI builds
# that and Terraform only references it. Adding a module to skip four resources
# would obscure more than it saves.

locals {
  function_name = "${var.namespace}-${var.environment}-${var.stage}-${var.function_purpose}"

  tags = merge(var.tags, {
    Namespace   = var.namespace
    Environment = var.environment
    Stage       = var.stage
  })
}

# Created explicitly rather than letting Lambda create it on first invocation.
# The implicit group has no retention set, so it keeps logs forever.
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = local.tags
}

resource "aws_iam_role" "this" {
  name                 = "${local.function_name}-role"
  permissions_boundary = var.permissions_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = local.tags
}

# Scoped to this function's own log group. The AWS-managed
# AWSLambdaBasicExecutionRole grants logs:* on every group in the account.
resource "aws_iam_role_policy" "logs" {
  name = "logs"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      Resource = "${aws_cloudwatch_log_group.this.arn}:*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count = var.vpc_config == null ? 0 : 1

  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  role          = aws_iam_role.this.arn

  # Artefact location, produced by CI. Nothing is built from this repository.
  s3_bucket        = var.artifact_bucket
  s3_key           = var.artifact_key
  source_code_hash = var.artifact_source_code_hash

  handler     = var.handler
  runtime     = var.runtime
  timeout     = var.timeout_seconds
  memory_size = var.memory_mb

  # Graviton. Cheaper per millisecond than x86 for the same work, and the only
  # cost of choosing it is that the artefact must be built for arm64.
  architectures = ["arm64"]

  # Reserved concurrency is a blast-radius control as much as a scaling one: it
  # caps how hard this function can hit a downstream database during a spike.
  reserved_concurrent_executions = var.reserved_concurrency

  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [var.vpc_config]

    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  environment {
    variables = var.environment_variables
  }

  # Without this the first invocation races the log group and Lambda creates an
  # unmanaged one with no retention.
  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy.logs,
  ]

  tags = local.tags
}
