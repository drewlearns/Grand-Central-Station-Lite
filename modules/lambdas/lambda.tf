resource "aws_lambda_function" "this_lambda" {
  for_each = var.lambdas

  function_name = each.key
  handler       = "${each.key}.handler"
  role          = aws_iam_role.this_lambda_role[each.key].arn
  runtime       = each.value.runtime
  filename      = "./deploy/${each.key}.zip"
  timeout       = 30
  memory_size   = 256
  tags = {
    Name = each.key
  }
  environment {
    variables = each.value.environment
  }
  vpc_config {
    subnet_ids         = var.lambda_vpc_subnet_ids
    security_group_ids = [var.lambda_vpc_security_group_ids]
  }
  depends_on = [null_resource.run_build_script, aws_iam_role_policy.lambda_vpc_access]
}

resource "aws_lambda_permission" "api_gateway_permission" {
  for_each      = var.lambdas
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = each.key
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this_api.execution_arn}/*/*"
  depends_on    = [aws_lambda_function.this_lambda]
}

# resource "aws_cloudwatch_log_group" "lambda_log_groups" {
#   for_each = var.lambdas

#   name              = "/aws/lambda/${each.key}"
#   retention_in_days = 7
# }
