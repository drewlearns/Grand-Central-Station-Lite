# resource "aws_cloudwatch_event_rule" "daily_trigger" {
#   name                = "daily-bill-notification-trigger"
#   description         = "Triggers the Lambda function to send bill notifications daily at 8 AM EST"
#   schedule_expression = "cron(0 13 * * ? *)" # 8 AM EST is 1 PM UTC
# }

# resource "aws_cloudwatch_event_target" "lambda_target" {
#   rule      = aws_cloudwatch_event_rule.daily_trigger.name
#   target_id = "send-bill-notifications"
#   arn       = aws_lambda_function.bill_notifications_lambda.arn
# }

# resource "aws_lambda_permission" "allow_eventbridge" {
#   statement_id  = "AllowExecutionFromEventBridge"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.bill_notifications_lambda.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
# }

# resource "aws_iam_role" "lambda_execution_role" {
#   name = "lambda_execution_role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_policy" "lambda_policy" {
#   name = "lambda_policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Resource = "arn:aws:logs:*:*:*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "sns:Publish"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "rds-data:ExecuteStatement"
#         ]
#         Resource = "arn:aws:rds:*:*:cluster:*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "attach_lambda_policy" {
#   role       = aws_iam_role.lambda_execution_role.name
#   policy_arn = aws_iam_policy.lambda_policy.arn
# }

# resource "aws_lambda_function" "bill_notifications_lambda" {
#   function_name = "bill-notifications"
#   role          = aws_iam_role.lambda_execution_role.arn
#   handler       = "AutoNotifications.handler"
#   runtime       = "nodejs20.x"
#   timeout       = 30
#   filename      = "./deploy/AutoNotifications.zip"
# }

# resource "aws_sns_topic" "bill_notifications_topic" {
#   name = "bill-notifications-topic"
# }

# resource "aws_sns_topic_subscription" "app_subscription" {
#   topic_arn = aws_sns_topic.bill_notifications_topic.arn
#   protocol  = "application"
#   endpoint  = "arn:aws:sns:your-region:your-account-id:endpoint/APNS_SANDBOX/your-app/your-endpoint"
# }
