# Conditionally create the domain name if a custom domain is specified
resource "aws_api_gateway_domain_name" "this_domain_name" {

  domain_name     = var.domain_name
  certificate_arn = aws_acm_certificate.cert.arn

  endpoint_configuration {
    types = ["EDGE"]
  }
}

# Base path mapping to connect the custom domain to the API deployment
resource "aws_api_gateway_base_path_mapping" "this_base_path_mapping" {
  depends_on = [aws_api_gateway_domain_name.this_domain_name, aws_route53_record.api_dns]

  domain_name = aws_api_gateway_domain_name.this_domain_name.domain_name
  api_id      = aws_api_gateway_rest_api.this_api.id
  stage_name  = aws_api_gateway_deployment.this_deployment.stage_name
}


resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "api_dns" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.this_domain_name.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.this_domain_name.cloudfront_zone_id
    evaluate_target_health = true
  }
}
