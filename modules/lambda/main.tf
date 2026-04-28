# =============================================================================
# LAMBDA MODULE
# =============================================================================
# Lambda runs your code without provisioning servers. You upload a zip file
# containing your code, and AWS runs it on demand when triggered.
#
# Key concepts:
#   - Runtime: the language environment (nodejs20.x, python3.12, etc.)
#   - Handler: which function to call (index.handler = index.mjs → handler())
#   - Timeout: max execution time (default 3s, max 15 min)
#   - Memory: 128 MB to 10 GB — more memory = more CPU = faster execution
#   - Environment variables: config passed to your code (like .env)
#   - Execution Role: IAM role that defines what your Lambda can access
#
# Billing: you pay per invocation + execution duration. First 1M requests/month free.
# =============================================================================

locals {
  name_prefix   = "${var.project_name}-${var.environment}"
  function_name = "${local.name_prefix}-api"
}

# ---------------------------------------------------------------------------
# PACKAGE THE LAMBDA CODE
# ---------------------------------------------------------------------------
# Lambda expects a .zip file. The "archive_file" data source creates one
# from your source directory. Every time the code changes, Terraform
# detects the new hash and updates the Lambda function.
# ---------------------------------------------------------------------------
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/lambda.zip"
}

# ---------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP
# ---------------------------------------------------------------------------
# Create the log group explicitly so we can control retention.
# If Lambda creates it automatically, logs are kept forever (expensive).
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 14

  tags = {
    Name = "${local.name_prefix}-lambda-logs"
  }
}

# ---------------------------------------------------------------------------
# IAM ROLE for Lambda
# ---------------------------------------------------------------------------
# Lambda needs an IAM role to:
#   1. Write logs to CloudWatch (so you can debug)
#   2. Read/write to DynamoDB (your application data)
#
# The "assume_role_policy" says WHO can use this role (Lambda service).
# The attached policies say WHAT the role can do.
# ---------------------------------------------------------------------------
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Allow Lambda to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambda to read/write to the specific DynamoDB table
# This is a custom inline policy — more secure than broad managed policies
# because it only grants access to THIS table, not all DynamoDB tables.
resource "aws_iam_role_policy" "dynamodb_access" {
  name = "${local.name_prefix}-dynamodb-access"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",    # Create/update items
          "dynamodb:GetItem",    # Read a single item by key
          "dynamodb:UpdateItem", # Update specific fields
          "dynamodb:DeleteItem", # Delete an item
          "dynamodb:Scan",       # Read all items (use sparingly)
          "dynamodb:Query",      # Read items by key condition
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# LAMBDA FUNCTION
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "api" {
  function_name = local.function_name
  role          = aws_iam_role.lambda.arn

  # Code package
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Runtime configuration
  runtime = "nodejs20.x"
  handler = "index.handler" # file: index.mjs, export: handler

  # Resource limits
  timeout     = 10  # seconds (API calls should be fast)
  memory_size = 128 # MB (128 is the minimum and cheapest)

  # Environment variables — accessible via process.env in your code
  environment {
    variables = {
      TABLE_NAME  = var.dynamodb_table_name
      ENVIRONMENT = var.environment
    }
  }

  # Ensure the log group exists before the function runs
  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = {
    Name = local.function_name
  }
}
