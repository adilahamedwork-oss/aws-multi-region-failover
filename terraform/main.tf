terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    route53  = "http://127.0.0.1:4566"
    dynamodb = "http://127.0.0.1:4566"
  }
}

# 1. DynamoDB Global Table (Active-Active Replication across us-east-1 and us-west-2)
resource "aws_dynamodb_table" "global_sessions" {
  name             = "GlobalUserSessions"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "sessionId"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "sessionId"
    type = "S"
  }

  replica {
    region_name = "us-west-2"
  }
}

# 2. Route 53 Hosted Zone
resource "aws_route53_zone" "primary_zone" {
  name = "failover.internal"
}

# 3. Route 53 Health Check for Region 1 (us-east-1)
resource "aws_route53_health_check" "region1_health" {
  ip_address        = "127.0.0.1"
  port              = 4566
  type              = "HTTP"
  resource_path     = "/_localstack/health"
  failure_threshold = 2
  request_interval  = 10
}

# 4. Route 53 Failover Routing Records
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.primary_zone.zone_id
  name    = "api.failover.internal"
  type    = "A"
  ttl     = 10

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "primary-us-east-1"
  records         = ["10.0.1.100"]
  health_check_id = aws_route53_health_check.region1_health.id
}

resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.primary_zone.zone_id
  name    = "api.failover.internal"
  type    = "A"
  ttl     = 10

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary-us-west-2"
  records        = ["10.0.2.200"]
}

output "hosted_zone_id" {
  value = aws_route53_zone.primary_zone.zone_id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.global_sessions.name
}
