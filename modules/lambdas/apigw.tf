resource "aws_api_gateway_rest_api" "this_api" {
  name        = "TPPB_API"
  description = "API Gateway for Lambda functions"
}

resource "aws_api_gateway_resource" "this_resource" {
  for_each    = var.lambdas
  rest_api_id = aws_api_gateway_rest_api.this_api.id
  parent_id   = aws_api_gateway_rest_api.this_api.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "options_method" {
  for_each = var.lambdas

  rest_api_id   = aws_api_gateway_rest_api.this_api.id
  resource_id   = aws_api_gateway_resource.this_resource[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  for_each = var.lambdas

  rest_api_id = aws_api_gateway_rest_api.this_api.id
  resource_id = aws_api_gateway_resource.this_resource[each.key].id
  http_method = aws_api_gateway_method.options_method[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_method_response" {
  for_each = var.lambdas

  rest_api_id = aws_api_gateway_rest_api.this_api.id
  resource_id = aws_api_gateway_resource.this_resource[each.key].id
  http_method = aws_api_gateway_method.options_method[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  for_each = var.lambdas

  depends_on = [aws_api_gateway_integration.options_integration]

  rest_api_id = aws_api_gateway_rest_api.this_api.id
  resource_id = aws_api_gateway_resource.this_resource[each.key].id
  http_method = aws_api_gateway_method.options_method[each.key].http_method
  status_code = aws_api_gateway_method_response.options_method_response[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST,GET,PUT,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'https://app.${var.domain_base}'"
  }
}

resource "aws_api_gateway_method" "this_method" {
  for_each = var.lambdas

  rest_api_id      = aws_api_gateway_rest_api.this_api.id
  resource_id      = aws_api_gateway_resource.this_resource[each.key].id
  http_method      = each.value.method
  authorization    = each.value.authorization
  authorizer_id    = aws_api_gateway_authorizer.cognito_authorizer.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda_integration" {
  for_each = var.lambdas

  rest_api_id = aws_api_gateway_rest_api.this_api.id
  resource_id = aws_api_gateway_resource.this_resource[each.key].id
  http_method = aws_api_gateway_method.this_method[each.key].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.this_lambda[each.key].invoke_arn
}

resource "aws_api_gateway_method_response" "method_response" {
  for_each = var.lambdas

  rest_api_id = aws_api_gateway_rest_api.this_api.id
  resource_id = aws_api_gateway_resource.this_resource[each.key].id
  http_method = aws_api_gateway_method.this_method[each.key].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "integration_response" {
  for_each = var.lambdas

  depends_on = [aws_api_gateway_integration.lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.this_api.id
  resource_id = aws_api_gateway_resource.this_resource[each.key].id
  http_method = aws_api_gateway_method.this_method[each.key].http_method
  status_code = aws_api_gateway_method_response.method_response[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST,GET,PUT,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'https://app.${var.domain_base}'"
  }
}

resource "aws_api_gateway_deployment" "this_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration,
    aws_api_gateway_integration_response.integration_response,
    aws_api_gateway_integration_response.options_integration_response,
  ]

  rest_api_id = aws_api_gateway_rest_api.this_api.id
  stage_name  = "v1"

  triggers = {
    redeployment = sha1(join("", [
      for k, v in aws_api_gateway_method.this_method : "${k}:${v.id}"
    ]))
  }
}

resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name            = "CognitoAuthorizer"
  type            = "COGNITO_USER_POOLS"
  rest_api_id     = aws_api_gateway_rest_api.this_api.id
  provider_arns   = [var.cognito_user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

resource "random_string" "api_key" {
  length  = 32
  special = false
}

resource "aws_api_gateway_api_key" "this_api_key" {
  name        = "MyAPIKey"
  description = "API Key for my API Gateway"
  enabled     = true
  value       = random_string.api_key.result
}

resource "aws_api_gateway_usage_plan" "this_usage_plan" {
  name        = "MyUsagePlan"
  description = "Usage plan for my API Gateway"
  api_stages {
    api_id = aws_api_gateway_rest_api.this_api.id
    stage  = aws_api_gateway_deployment.this_deployment.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "this_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.this_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this_usage_plan.id
}

resource "aws_secretsmanager_secret" "api_key_secret" {
  name = "api-secret"
}

resource "aws_secretsmanager_secret_version" "api_key_secret_version" {
  secret_id     = aws_secretsmanager_secret.api_key_secret.id
  secret_string = <<EOF
{
  "api_key": "${random_string.api_key.result}"
}
EOF
}
