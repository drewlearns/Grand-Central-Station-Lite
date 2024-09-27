
output "tunnel_command" {
  description = "run this before trying to connect with pgadmin"
  value       = "ssh -i ~/bastion-key -N -L 5432:${aws_rds_cluster.aurora_cluster.endpoint}:5432 ec2-user@${aws_instance.bastion.public_ip}"
}
