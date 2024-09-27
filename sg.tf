# Security Groups
resource "aws_security_group" "bastion_sg" {
  name   = "bastion_sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.static_ip}/32"] # Replace with your actual IP for SSH access
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["${var.static_ip}/32"] # Replace with your actual IP for SSH access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Aurora Security Group
resource "aws_security_group" "aurora_sg" {
  name   = "aurora_sg"
  vpc_id = aws_vpc.main.id
}

# Lambda Security Group
resource "aws_security_group" "lambda_sg" {
  name   = "lambda_sg"
  vpc_id = aws_vpc.main.id

  # General egress rule - adjust or remove based on your needs
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Ingress rule to allow Lambda to connect to Aurora
resource "aws_security_group_rule" "aurora_from_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aurora_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
}

# Outbound rule to allow Lambda to access Aurora
resource "aws_security_group_rule" "lambda_to_aurora" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_sg.id
  source_security_group_id = aws_security_group.aurora_sg.id
}

# Ingress rule to allow Bastion to connect to Aurora
resource "aws_security_group_rule" "aurora_from_bastion" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aurora_sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}

# Outbound rule to allow Bastion to access Aurora
resource "aws_security_group_rule" "bastion_to_aurora" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.bastion_sg.id
  source_security_group_id = aws_security_group.aurora_sg.id
}
