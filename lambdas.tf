module "lambdas" {
  source                        = "./modules/lambdas"
  zone_id                       = var.zone_id
  domain_name                   = var.domain_name
  cognito_user_pool_arn         = aws_cognito_user_pool.cognito_user_pool.arn
  lambda_vpc_subnet_ids         = [aws_subnet.private1.id, aws_subnet.private2.id]
  lambda_vpc_security_group_ids = aws_security_group.lambda_sg.id
  aurora_endpoint               = aws_rds_cluster.aurora_cluster.endpoint
  db_password                   = aws_secretsmanager_secret_version.db_master_password_version.secret_string
  db_username                   = "root"
  db_name                       = "tppb${var.environment}"
  database_url                  = "postgresql://root:${aws_secretsmanager_secret_version.db_master_password_version.secret_string}@${aws_rds_cluster.aurora_cluster.endpoint}:5432/tppb${var.environment}?schema=public"
  lambdas = {
    "EXAMPLE" = {
      runtime       = "nodejs20.x"
      method        = "POST" # CAN ONLY BE POST YOU CAN TRY GET BUT FOR SOME REASON I WAS UNABLE TO GET ANYTHING BUT POST TO WORK MAKING THIS NOT VERY RESTFUL BUT THATS OK
      authorization = "NONE" # "NONE" OR "COGNITO_USER_POOLS" USE COGNITOR_USER_POOLS IF YOU WANT TO SECURE THE ENDPOINTS USING COGNITO. OTHERWISE, COMMENT OUT ALL OF COGNITO.TF
      policy_arns   = [aws_iam_policy.ses_send_email_policy.arn, aws_iam_policy.lambda_cognito_create_user_policy.arn] # see iam_policies.tf file for which ones to attache
      environment = {
        DATABASE_URL = "postgresql://root:${aws_secretsmanager_secret_version.db_master_password_version.secret_string}@${aws_rds_cluster.aurora_cluster.endpoint}:5432/tppb${var.environment}?schema=public"
      }
    },
  }
}
