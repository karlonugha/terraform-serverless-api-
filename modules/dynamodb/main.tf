# =============================================================================
# DYNAMODB MODULE
# =============================================================================
# DynamoDB is a serverless NoSQL database. Unlike RDS (which runs 24/7 on a
# server), DynamoDB has no instances to manage — you just define a table
# and AWS handles everything.
#
# Key concepts:
#   - Table: like a database table, but schema-less (no fixed columns)
#   - Partition Key: the primary key used to distribute data (like an ID)
#   - Billing Mode: PAY_PER_REQUEST means you pay only for reads/writes
#   - No connection strings, no passwords — Lambda accesses it via IAM
# =============================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_dynamodb_table" "urls" {
  name         = "${local.name_prefix}-urls"
  billing_mode = "PAY_PER_REQUEST" # No capacity planning needed — scales automatically

  # Only define the key attributes here.
  # DynamoDB is schema-less — you can store any other fields without declaring them.
  hash_key = "code" # Partition key — the short URL code (e.g., "a1b2c3")

  attribute {
    name = "code"
    type = "S" # S = String, N = Number, B = Binary
  }

  # Enable point-in-time recovery for data protection
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${local.name_prefix}-urls"
  }
}
