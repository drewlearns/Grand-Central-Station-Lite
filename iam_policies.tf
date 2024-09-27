data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "lambda_sns_policy" {
  name = "lambda_sns_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "sns:Publish"
        ],
        Resource = "arn:aws:sns:*:*:*",
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_cognito_create_user_policy" {
  name = "lambda_cognito_create_user_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminRespondToAuthChallenge",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminDeleteUser"
        ],
        Resource = [
          "arn:aws:cognito-idp:*:*:userpool/*",
          "arn:aws:cognito-identity:*:*:identitypool/*"

        ]
      }
    ]
  })
}
resource "aws_iam_policy" "lambda_cognito_disable_user_policy" {
  name = "lambda_cognito_disable_user_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:AdminDisableUser"
        ],
        Resource = [
          "arn:aws:cognito-idp:*:*:userpool/*",
          "arn:aws:cognito-identity:*:*:identitypool/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_cognito_login_policy" {
  name = "lambda_cognito_login_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:AdminInitiateAuth",
          "cognito-idp:AdminRespondToAuthChallenge",
        ],
        Resource = [
          "arn:aws:cognito-idp:*:*:userpool/*",
          "arn:aws:cognito-identity:*:*:identitypool/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name = "lambda_s3_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:*",
        ],
        Resource = [
          aws_s3_bucket.receipts_bucket.arn,
          "${aws_s3_bucket.receipts_bucket.arn}/*",
        ],
        Effect = "Allow"
      },
      {
        Action = [
          "s3:ListAllMyBuckets",
        ],
        Resource = "*",
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_invoke_policy" {
  name        = "LambdaInvokePolicy"
  description = "Policy to allow invoking another Lambda function"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = [
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:*",
        ]
      },
    ],
  })
}

resource "aws_iam_policy" "lambda_textract_policy" {
  name        = "lambda_textract_policy"
  path        = "/"
  description = "IAM policy for Lambda function to access AWS Textract"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "textract:AnalyzeDocument"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "arn:aws:s3:::your-textract-bucket/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "forgot_password_policy" {
  name        = "ForgotPasswordPolicy"
  path        = "/"
  description = "Policy for Forgot Password Lambda function to access Cognito"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:ForgotPassword"
        ]
        Resource = [
          aws_cognito_user_pool.cognito_user_pool.arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "confirm_user_policy" {
  name        = "confirm_user_policy"
  path        = "/"
  description = "Policy for Forgot Password Lambda function to access Cognito"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:ConfirmSignUp"
        ]
        Resource = [
          aws_cognito_user_pool.cognito_user_pool.arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "ses_send_email_policy" {
  name        = "ses_send_email_policy"
  description = "Allow Lambda to send email via SES"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:ses:us-east-1:339712783646:identity/noreply@app.${var.domain_base}"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_secrets_policy" {
  name        = "LambdaSecretsPolicy"
  description = "Policy for Lambda to manage secrets with /bills/* pattern in Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:CreateSecret",
          "secretsmanager:UpdateSecret"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:bill-credentials/*",
        ]
      }
    ]
  })
}
