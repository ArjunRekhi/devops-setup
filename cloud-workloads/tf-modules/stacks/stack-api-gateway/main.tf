# HTTP API in front of the Lambda function.
#
# HTTP API rather than REST API: roughly a third of the price, lower latency,
# and the REST-only features (request validation models, WAF at the stage,
# API keys with usage plans) are not needed here. Swapping later is a rewrite,
# so it is worth being deliberate about.

locals {
  name = "${var.namespace}-${var.environment}-${var.stage}-api"

  tags = merge(var.tags, {
    Namespace   = var.namespace
    Environment = var.environment
    Stage       = var.stage
  })
}

resource "aws_apigatewayv2_api" "this" {
  name          = local.name
  protocol_type = "HTTP"
  description   = "${var.namespace} ${var.environment} HTTP API"

  # Browsers will not call this cross-origin without it, and the failure is a
  # preflight rejection that looks nothing like a CORS problem in the logs.
  dynamic "cors_configuration" {
    for_each = var.cors_allowed_origins == null ? [] : [1]

    content {
      allow_origins = var.cors_allowed_origins
      allow_methods = ["GET", "POST", "OPTIONS"]
      allow_headers = ["content-type", "authorization"]
      max_age       = 3600
    }
  }

  tags = local.tags
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.this.id

  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = "2.0"

  # Must be shorter than the Lambda timeout, or the client is told the request
  # failed while the function is still running and still being billed.
  timeout_milliseconds = var.integration_timeout_ms
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = var.route_key
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"

  authorization_type = var.jwt_authorizer == null ? "NONE" : "JWT"
  authorizer_id      = var.jwt_authorizer == null ? null : aws_apigatewayv2_authorizer.jwt[0].id
}

# Validates the token at the edge, so an unauthenticated request never reaches
# the function and never costs an invocation.
resource "aws_apigatewayv2_authorizer" "jwt" {
  count = var.jwt_authorizer == null ? 0 : 1

  api_id           = aws_apigatewayv2_api.this.id
  name             = "${local.name}-jwt"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = var.jwt_authorizer.issuer
    audience = var.jwt_authorizer.audience
  }
}

# API Gateway is a service principal, not a caller with a role, so permission to
# invoke is granted on the function rather than assumed by the API.
resource "aws_lambda_permission" "api" {
  statement_id  = "AllowInvokeFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # Scoped to this API. Without it, any API Gateway in the account could invoke
  # the function.
  source_arn = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "access" {
  name              = "/aws/apigateway/${local.name}"
  retention_in_days = var.log_retention_days

  tags = local.tags
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.access.arn

    # JSON rather than CLF, so the logs are queryable in Insights without a
    # regex. integrationErrorMessage is the field that explains a 500 that the
    # status code alone will not.
    format = jsonencode({
      requestId               = "$context.requestId"
      requestTime             = "$context.requestTime"
      httpMethod              = "$context.httpMethod"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLatency         = "$context.responseLatency"
      integrationStatus       = "$context.integrationStatus"
      integrationErrorMessage = "$context.integrationErrorMessage"
      sourceIp                = "$context.identity.sourceIp"
    })
  }

  # A public endpoint with no ceiling is an open invitation to a bill. These are
  # per-stage limits, applied before the request reaches the function.
  default_route_settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }

  tags = local.tags
}

# The generated execute-api hostname is not something to publish. A custom
# domain gives a stable name, given a certificate ARN and hosted zone ID from
# wherever DNS is managed. Left unset here, so these resources do not render.
resource "aws_apigatewayv2_domain_name" "this" {
  count = var.custom_domain == null ? 0 : 1

  domain_name = var.custom_domain.domain_name

  domain_name_configuration {
    certificate_arn = var.custom_domain.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = local.tags
}

resource "aws_apigatewayv2_api_mapping" "this" {
  count = var.custom_domain == null ? 0 : 1

  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.this[0].id
  stage       = aws_apigatewayv2_stage.this.id
}

resource "aws_route53_record" "this" {
  count = var.custom_domain == null ? 0 : 1

  zone_id = var.custom_domain.zone_id
  name    = var.custom_domain.domain_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.this[0].domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
