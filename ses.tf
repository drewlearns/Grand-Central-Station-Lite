resource "aws_ses_domain_identity" "email_domain" {
  domain = "app.${var.domain_base}"
}

resource "aws_ses_email_identity" "email_address" {
  email = "noreply@app.${var.domain_base}"
}

resource "aws_ses_domain_dkim" "email_dkim" {
  domain = aws_ses_domain_identity.email_domain.domain
}

resource "aws_route53_record" "ses_verification" {
  zone_id = "Z08879961LIWSLO8I14AQ"
  name    = "_amazonses.app.${var.domain_base}"
  type    = "TXT"
  ttl     = 300
  records = [aws_ses_domain_identity.email_domain.verification_token]
}

resource "aws_route53_record" "ses_dkim" {
  count   = 3
  zone_id = "Z08879961LIWSLO8I14AQ"
  name    = element(aws_ses_domain_dkim.email_dkim.dkim_tokens, count.index)
  type    = "CNAME"
  ttl     = 300
  records = [element(aws_ses_domain_dkim.email_dkim.dkim_tokens, count.index)]
}

resource "aws_ses_domain_identity_verification" "email_verification" {
  domain     = aws_ses_domain_identity.email_domain.domain
  depends_on = [aws_route53_record.ses_verification]
}
