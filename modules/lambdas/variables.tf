variable "lambdas" {
  description = "lambdas configuration object"
  type = map(object({
    runtime       = string
    method        = string
    authorization = string
    policy_arns   = list(string)
    environment   = map(string)
  }))
}

variable "database_url" {
  type        = string
  description = "passed in database URL"
}

variable "zone_id" {
  description = "zone id for api dns hosted zone"
  type        = string
}

variable "domain_name" {
  description = "domain name for api gateway"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "arn of the cognito user pool"
  type        = string
}

variable "lambda_vpc_subnet_ids" {
  description = "ids of lambda security groups"
  type        = list(string)
}

variable "lambda_vpc_security_group_ids" {
  description = "security group ids for lambda"
  type        = string
}

variable "aurora_endpoint" {
  description = "aws_rds_cluster_instance.aurora_instance.endpoint"
  type        = string
}

# Define variables for database connection details
variable "db_username" {
  description = "rds database username (root) typically"
  type        = string
  default     = "root"
}
variable "db_password" {
  description = "Master db password for rds"
  type        = string
}
variable "db_name" {
  description = "RDS Database name, typically tppb-environment"
  type        = string
  default     = "tppb-dev"
}
