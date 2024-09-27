
# Bastion Host
resource "aws_instance" "bastion" {
  ami           = "ami-07caf09b362be10b8" # Update with the latest Amazon Linux 2 AMI for us-east-1
  instance_type = "t2.micro"
  key_name      = "bastion-key"

  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  associate_public_ip_address = true
  depends_on                  = [aws_key_pair.bastion_key]
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = "${var.public_ssh_key}"
}
