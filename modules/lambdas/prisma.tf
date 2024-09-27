# Generate the content for the .env file using templatefile
locals {
  env_content = templatefile("${path.module}/env.template", {
    username      = var.db_username
    password      = var.db_password
    endpoint      = var.aurora_endpoint
    database_name = var.db_name
  })
}

# Create the .env file
resource "local_file" "env_file" {
  content  = local.env_content
  filename = "${path.root}/.env"
}

# Run the build script after creating the .env file
resource "null_resource" "run_build_script" {
  # Ensure this runs after the .env file is created
  depends_on = [local_file.env_file]

  provisioner "local-exec" {
    command = "./build"
  }
}
