variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "source_dir" {
  description = "Path to the Lambda source code directory"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table (for IAM permissions)"
  type        = string
}
