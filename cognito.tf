resource "aws_cognito_user_pool" "cognito_user_pool" {
  name = "budget_app_user_pool"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account  = "DEVELOPER"
    source_arn             = "arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:identity/noreply@app.${var.domain_base}"
    from_email_address     = "noreply@app.${var.domain_base}"
    reply_to_email_address = "help@${var.domain_base}"
  }
}


resource "aws_cognito_user_pool_client" "cognito_user_pool_client" {
  name         = "TPPBClient"
  user_pool_id = aws_cognito_user_pool.cognito_user_pool.id

  generate_secret     = true
  explicit_auth_flows = ["ALLOW_USER_SRP_AUTH", "ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_CUSTOM_AUTH"]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = ["https://app.${var.domain_base}/dashboard"]
  logout_urls   = ["https://app.${var.domain_base}/logout"]
}

resource "aws_iam_policy" "cognito_ses_policy" {
  name        = "CognitoSESPolicy"
  description = "IAM policy for Cognito to send emails via SES"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail",
          "sns:Publish"
        ],
        Resource = "arn:aws:ses:${var.region}:${data.aws_caller_identity.current.account_id}:identity/noreply@${var.domain_name}"
      }
    ]
  })
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cognito-idp.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cognito_user_pool_role" {
  name               = "CognitoUserPoolRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "cognito_ses_policy_attachment" {
  role       = aws_iam_role.cognito_user_pool_role.name
  policy_arn = aws_iam_policy.cognito_ses_policy.arn
}
