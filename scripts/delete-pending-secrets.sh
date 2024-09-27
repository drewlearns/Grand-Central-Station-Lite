#!/bin/bash

# Ensure AWS CLI is installed and configured with the right permissions
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install and configure it before running this script."
    exit 1
fi

# List all secrets including those pending deletion
secrets_in_deletion=$(aws secretsmanager list-secrets --include-planned-deletion \
    --query 'SecretList[?DeletionDate!=null].[ARN]' \
    --output text)

# Check if there are any secrets in 'Pending Deletion' state
if [ -z "$secrets_in_deletion" ]; then
    echo "No secrets are pending deletion."
    exit 0
fi

# Iterate over each secret and force delete it
for secret_arn in $secrets_in_deletion; do
    echo "Force deleting secret: $secret_arn"
    aws secretsmanager delete-secret --secret-id "$secret_arn" --force-delete-without-recovery
    if [ $? -eq 0 ]; then
        echo "Successfully deleted secret: $secret_arn"
    else
        echo "Failed to delete secret: $secret_arn"
    fi
done

echo "Completed processing all pending deletion secrets."
