
locals {
  role_policy_attachments = flatten([
    for lambda_name, lambda_details in var.lambdas : [
      for idx in range(length(lambda_details.policy_arns)) : {
        role_name  = lambda_name,
        policy_arn = lambda_details.policy_arns[idx],
        unique_id  = "${lambda_name}-${idx}"
      }
    ]
  ])
}
