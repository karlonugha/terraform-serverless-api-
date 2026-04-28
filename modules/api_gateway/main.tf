# =============================================================================
# API GATEWAY MODULE
# =============================================================================
# API Gateway is the front door for your serverless API. It receives HTTP
# requests from the internet and routes them to your Lambda function.
#
# We're using HTTP API (v2) — it's simpler, cheaper, and faster than
# REST API (v1). Perfect for Lambda integrations.
#
# Key concepts:
#   - API: the top-level resource (your API definition)
#   - Stage: a deployment environment ($default, prod, staging)
#   - Integration: connects the API to a backend (Lambda)
#   - Route: maps HTTP method + path to an integration
#
# Flow: Client → API Gateway → Lambda → Response → Client
# =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# HTTP API
# ---------------------------------------------------------------------------
# This creates the API itself. The "protocol_type" is HTTP (not WEBSOCKET).
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "main" {
  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"
  description   = "URL Shortener API"

  # CORS configuration — allows browsers to call your API
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
    max_age       = 3600
  }

  tags = {
    Name = "${local.name_prefix}-api"
  }
}

# ---------------------------------------------------------------------------
# STAGE
# ---------------------------------------------------------------------------
# A stage is like a deployment slot. $default is the default stage —
# requests go directly to your API URL without a stage prefix.
#
# auto_deploy = true means changes are deployed immediately.
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  # Access logging — logs every API request to CloudWatch
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      method         = "$context.httpMethod"
      path           = "$context.path"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      latency        = "$context.responseLatency"
    })
  }

  tags = {
    Name = "${local.name_prefix}-default-stage"
  }
}

# CloudWatch log group for API Gateway access logs
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = 14

  tags = {
    Name = "${local.name_prefix}-api-logs"
  }
}

# ---------------------------------------------------------------------------
# LAMBDA INTEGRATION
# ---------------------------------------------------------------------------
# This connects API Gateway to your Lambda function.
# "AWS_PROXY" means API Gateway passes the full HTTP request to Lambda
# and returns Lambda's response directly to the client.
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.lambda_invoke_arn
  integration_method = "POST" # Lambda integrations always use POST internally

  # Payload format version 2.0 gives a cleaner event structure
  payload_format_version = "2.0"
}

# ---------------------------------------------------------------------------
# ROUTES
# ---------------------------------------------------------------------------
# Routes map HTTP requests to the Lambda integration.
# "$default" is a catch-all route — any request not matching a specific
# route goes here. This lets Lambda handle all routing logic internally.
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_route" "catch_all" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$default" # Catch-all: any method, any path

  target = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# ---------------------------------------------------------------------------
# LAMBDA PERMISSION
# ---------------------------------------------------------------------------
# API Gateway needs explicit permission to invoke your Lambda function.
# Without this, API Gateway gets "Access Denied" when trying to call Lambda.
# ---------------------------------------------------------------------------
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
