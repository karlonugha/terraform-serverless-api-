# =============================================================================
# VARIABLES
# =============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "url-shortener"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}
