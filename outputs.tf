# =============================================================================
# OUTPUTS
# =============================================================================

output "api_url" {
  description = "Public API URL — use this to call your API"
  value       = module.api_gateway.api_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.lambda.function_name
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "test_commands" {
  description = "Commands to test your API"
  value       = <<-EOT

    ============================================================
    API is live! Test it with these commands:
    ============================================================

    1. Health check:
       curl ${module.api_gateway.api_url}/health

    2. Create a short URL:
       curl -X POST ${module.api_gateway.api_url}/shorten -H "Content-Type: application/json" -d "{\"url\": \"https://github.com/karlonugha\"}"

    3. Visit the short URL (use the code from step 2):
       curl -v ${module.api_gateway.api_url}/<code>

    4. View Lambda logs:
       aws logs tail /aws/lambda/${module.lambda.function_name} --follow

    5. Destroy when done:
       terraform destroy
    ============================================================
  EOT
}
