# =============================================================================
# ROOT MODULE
# =============================================================================
# Wires together: DynamoDB → Lambda → API Gateway
#
# Compare this to the ECS project (5 modules, 31 resources).
# Serverless is simpler — no VPC, no subnets, no load balancer, no NAT.
# =============================================================================

# 1. DynamoDB — the database
module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment
}

# 2. Lambda — the application code
module "lambda" {
  source = "./modules/lambda"

  project_name        = var.project_name
  environment         = var.environment
  source_dir          = "${path.module}/src"
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn
}

# 3. API Gateway — the public HTTP endpoint
module "api_gateway" {
  source = "./modules/api_gateway"

  project_name         = var.project_name
  environment          = var.environment
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
}
