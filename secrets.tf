# # Store the secret in AWS Secrets Manager then fetch them with data blocks below
# data "aws_secretsmanager_secret" "stripe" {
#   name                    = "prod-stripe-sk"
# }

# data "aws_secretsmanager_secret_version" "stripe_version" {
#     secret_id = data.aws_secretsmanager_secret.stripe.id
# }

# data "aws_secretsmanager_secret" "revenuecat" {
#   name = "revenueCatApiKey"
# }

# data "aws_secretsmanager_secret_version" "revenuecat" {
#   secret_id = data.aws_secretsmanager_secret.revenuecat.id
# }