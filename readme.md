# Grand Central Station

<!-- TOC -->

- [Grand Central Station](#the-purple-piggybank---grand-central-station)
  - [About](#about)
  - [Deploying](#deploying)
    - [Initial deployment](#initial-deployment)
  - [Adding new lambdas](#adding-new-lambdas)
  - [Connecting to the database](#connecting-to-the-database)
  - [Seeding the database](#seeding-the-database)
    - [How to drop all tables from the database:](#how-to-drop-all-tables-from-the-database)
  - [Precommit - Update the terraform docs below:](#precommit---update-the-terraform-docs-below)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Resources](#resources)
<!-- /TOC -->

## About

This repository is a "hub" for all things AWS backend and infrastructure. It's structured as a monorepo and most operations will happen in either the `src/` or `lambdas.tf` locations.
The idea is that this is a serverless hub such that all you have to do is populate a list of lambdas (api-end points) and add the logic to src/ directory. The lambda/js file/api endpoint will all be named the same.

Total monthly resource cost will bottom out about $100 in AWS. 

## Benefits

- highly resilient infrastructure
- highly available
- scalability to infinity
- Only pay for what you use
- highly performant and secure
- simple api backend development - just a lambda file (src/*.js)
- build process already defined
- prisma process already defined
- bastion created for secure access to database

## Cons

- slow cold start for lambdas - faster as more people are using it.
- prisma adds overhead to the lambda cold start time but speed of development and safety outweigh this negative
- need to know terraform like a boss
- DDOS could cost a fortune, need a WAF to avoid excessive fees

## Prerequisits

- terraform (`brew install terraform`)
- pre-commit (`brew install pre-commit` or `pipx install pre-commit`)
- npm
- Domain hosted in a management account
    - hosted zones created in dev and production account - you need to have the zone ID for the tfvars file
- update tfvars/dev.tfvars and tfvars/prod.tfvars
- backend.tf - update terraform state bucket name
- static IP address

### Initial deployment

```bash
npm i
npx prisma generate
./build # Takes ~30 minutes with all lambdas populated
terraform apply -var-file=./tfvars/dev.tfvars -auto-approve
# Connect to database locally (see instructions below on seeding the database)
# update .env file to "local" temporarily
./prisma
```

## Deploying

```bash
./build
terraform apply -var-file=./tfvars/dev.tfvars -auto-approve
```

## Prisma ORM

- Create a database diagram at dbdiagram.io and then convert the code to prisma and populate the prisma/prisma.schema file
- Update the prisma/seed.js to seed your database appropriately

## Adding new lambdas

Add new lambdas to lambdas.tf in the root directory. They should be post request and follow the same patterns as other lambdas for convention. These should be named based on the .js file name and they should use aws-sdk v3 only

## Connecting to the database

If you'd like to connect to the database, use the output command from terraform apply or look in outputs.tf for how to construct it.

Run the command, it will open a tunnel from local through the bastion host to the rds database. From there log in through pgadmin4. You can get the database credentials from secrets manager.

## Seeding the database

1. Open a connection to the database (see instructions in [Connecting to the database](#connecting-to-the-database))
2. Update .env file to "localhost" instead of the tppbdev/tppbprod endpoint (see env.template file that outputs to .env in the root after first terraform apply)
0. run `./prisma.sh`
0. This will seed the database.

> You may need to dump all tables first before seeding if the database already has been seeded. This is necessary when making development database schema.prisma changes.

### How to drop all tables from the database:

>❗️WARNING❗️**DO NOT** do this on prod database unless you are confident with what you are doing!

```sql
DO $$
DECLARE
    r RECORD;
BEGIN
    -- This query fetches all table names in the 'public' schema of your database
    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        -- Construct and execute a DROP TABLE statement for each table
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE;';
    END LOOP;
END $$;
```

## Precommit - Update the terraform docs below:

`brew install pre-commit`
`pre-commit install`
`pre-commit run -a` <-- This will update terraform docs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.42.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.42.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambdas"></a> [lambdas](#module\_lambdas) | ./modules/lambdas | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cognito_user_pool.cognito_user_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.cognito_user_pool_client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_db_subnet_group.aurora_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_policy.cognito_ses_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.confirm_user_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.forgot_password_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_cognito_create_user_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_cognito_disable_user_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_cognito_login_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_invoke_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_secrets_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_sns_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lambda_textract_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ses_send_email_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cognito_user_pool_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cognito_ses_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_internet_gateway.gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_key_pair.bastion_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_nat_gateway.nat_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_rds_cluster.aurora_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.aurora_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_s3_bucket.receipts_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.receipts_bucket_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_secretsmanager_secret.db_master_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.db_master_password_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.aurora_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.bastion_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.lambda_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.aurora_from_bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.aurora_from_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.bastion_to_aurora](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.lambda_to_aurora](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_subnet.private1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.s3_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [random_password.master_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_secretsmanager_secret.zoho](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.zoho_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | domain name | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | environment | `string` | n/a | yes |
| <a name="input_max_capacity"></a> [max\_capacity](#input\_max\_capacity) | max capacity of instances for rds serverless v2 scaling configuration | `number` | `1` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to create resources in. | `string` | `"us-east-1"` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | hosted zone Id | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tunnel_command"></a> [tunnel\_command](#output\_tunnel\_command) | run this before trying to connect with pgadmin |
<!-- END_TF_DOCS --># Grand-Central-Station-Lite
