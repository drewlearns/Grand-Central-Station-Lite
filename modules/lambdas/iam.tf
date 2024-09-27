resource "aws_iam_role" "this_lambda_role" {
  for_each = var.lambdas
  name     = "${each.key}_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Attach the AWSLambdaBasicExecutionRole policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  for_each = aws_iam_role.this_lambda_role # Match the same for_each used in the IAM role definition

  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  for_each = { for att in local.role_policy_attachments : att.unique_id => att }

  role       = aws_iam_role.this_lambda_role[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

# Create a policy document that allows EC2 network interface operations
data "aws_iam_policy_document" "lambda_vpc_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
    ]
    resources = ["*"]
  }
}

# Create and attach an inline policy to the Lambda IAM role
resource "aws_iam_role_policy" "lambda_vpc_access" {
  for_each = var.lambdas
  name     = "${each.key}_lambda_vpc_access_policy"
  role     = aws_iam_role.this_lambda_role[each.key].name
  policy   = data.aws_iam_policy_document.lambda_vpc_policy.json
}
