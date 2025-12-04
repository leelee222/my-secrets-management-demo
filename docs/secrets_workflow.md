# AWS Secrets Manager Setup Guide

This guide walks you through setting up and using AWS Secrets Manager with Terraform.

## Prerequisites

- AWS CLI installed and configured
- Terraform >= 1.0.0
- AWS account with appropriate permissions
- IAM user or role with secrets management permissions

## Quick Start

### 1. Configure AWS Credentials

```bash
aws configure
```

### 2. Prepare Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and add your secret values:

```hcl
environment = "dev"
region      = "us-east-1"

# Generate secure values
api_key_value    = "your-api-key"
db_username      = "admin"
db_password      = "your-secure-password"
db_host          = "database.example.com"
jwt_secret_value = "your-jwt-secret"
```

### 3. Initialize and Apply Terraform

```bash
terraform init
terraform plan
terraform apply
```

### 4. Verify Secrets Creation

```bash
aws secretsmanager list-secrets --region us-east-1
../scripts/fetch_secret.sh dev/api_key
```

## Features

### KMS Encryption
- All secrets are encrypted using AWS KMS
- Automatic key rotation enabled
- Custom KMS key for better control

### Tagging Strategy
- Environment tags (dev, staging, prod)
- Resource categorization
- Cost allocation tracking

### Recovery Window
- 7-day recovery window for accidental deletions
- Secrets can be restored within the window
- Prevents immediate permanent deletion

### JSON Secret Format
- Structured secret storage
- Multiple values per secret
- Metadata included (timestamps, versions)

### IAM Policy
- Least privilege access
- Separate read policy
- KMS decrypt permissions included

## Secret Structure

### API Key Secret
```json
{
  "api_key": "your-api-key",
  "created_at": "2025-12-02T..."
}
```

### Database Credentials Secret
```json
{
  "username": "admin",
  "password": "secure-password",
  "host": "database.example.com",
  "port": 5432,
  "database": "appdb"
}
```

### JWT Secret
```json
{
  "secret": "your-jwt-secret",
  "algorithm": "HS256",
  "expiration": "24h"
}
```

## Using Secrets in Applications

### AWS CLI
```bash
aws secretsmanager get-secret-value \
    --secret-id dev/api_key \
    --region us-east-1 \
    --query 'SecretString' \
    --output text | jq -r '.api_key'
```

### Python (boto3)
```python
import boto3
import json

client = boto3.client('secretsmanager', region_name='us-east-1')

def get_secret(secret_name):
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response['SecretString'])

api_key = get_secret('dev/api_key')['api_key']
```

### Node.js (AWS SDK v3)
```javascript
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

const client = new SecretsManagerClient({ region: "us-east-1" });

async function getSecret(secretName) {
    const response = await client.send(
        new GetSecretValueCommand({ SecretId: secretName })
    );
    return JSON.parse(response.SecretString);
}

const apiKey = (await getSecret('dev/api_key')).api_key;
```

### Bash Script
```bash
SECRET_VALUE=$(aws secretsmanager get-secret-value \
    --secret-id dev/api_key \
    --region us-east-1 \
    --query 'SecretString' \
    --output text)

API_KEY=$(echo "$SECRET_VALUE" | jq -r '.api_key')
```

## GitHub Actions Integration

```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::ACCOUNT:role/github-actions-role
    aws-region: us-east-1

- name: Fetch Secret
  env:
    SECRET_NAME: dev/api_key
  run: |
    SECRET_VALUE=$(aws secretsmanager get-secret-value \
      --secret-id $SECRET_NAME \
      --query 'SecretString' \
      --output text)
    
    echo "::add-mask::$SECRET_VALUE"
    echo "SECRET_VALUE=$SECRET_VALUE" >> $GITHUB_ENV
```

## Best Practices

### DO
- Use separate secrets for different environments (dev, staging, prod)
- Enable KMS encryption for all secrets
- Implement secret rotation for database credentials
- Use IAM policies with least privilege
- Tag all resources for better organization
- Set appropriate recovery windows
- Use JSON format for complex secrets
- Mask secrets in CI/CD logs

### DON'T
- Hardcode secrets in code
- Commit `terraform.tfvars` to version control
- Print secrets in logs
- Share secrets via email or chat
- Use default encryption
- Grant overly broad IAM permissions
- Skip tagging resources

## Secret Rotation (Advanced)

To enable automatic secret rotation:

1. Create a Lambda function for rotation
2. Uncomment the rotation configuration in `secrets.tf`
3. Apply Terraform changes

Example rotation Lambda:
```python
import boto3

def lambda_handler(event, context):
    client = boto3.client('secretsmanager')
    # Implement rotation logic
    pass
```

## Troubleshooting

### Issue: "Access Denied" when fetching secrets
**Solution**: Ensure your IAM user/role has the secrets read policy attached:
```bash
aws iam attach-user-policy \
    --user-name YOUR_USER \
    --policy-arn $(terraform output -raw secrets_read_policy_arn)
```

### Issue: KMS DecryptionFailure
**Solution**: Grant KMS decrypt permissions:
```bash
aws kms create-grant \
    --key-id $(terraform output -raw kms_key_id) \
    --grantee-principal YOUR_ARN \
    --operations Decrypt
```

### Issue: Secret not found
**Solution**: Check the secret name and region:
```bash
aws secretsmanager list-secrets --region us-east-1
```

## Cost Considerations

- **Secret Storage**: $0.40 per secret per month
- **API Calls**: $0.05 per 10,000 API calls
- **KMS**: $1.00 per key per month + API call charges

**Example monthly cost for this setup**:
- 3 secrets × $0.40 = $1.20
- 1 KMS key = $1.00
- **Total: ~$2.20/month** (excluding API calls)

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy
```

**Warning**: This will permanently delete all secrets after the recovery window expires.

## Additional Resources

- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Security Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review AWS CloudTrail logs
3. Check Terraform state
4. Review IAM permissions
