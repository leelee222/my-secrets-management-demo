# AWS Secrets Manager - DevSecOps Beginner Guide

## What You'll Learn

This guide will teach you how to securely store and manage secrets using AWS Secrets Manager with Terraform. By the end, you'll understand how to create, retrieve, and use secrets in a production-ready way.

## What is AWS Secrets Manager?

AWS Secrets Manager is a service that helps you securely store, manage, and retrieve sensitive information like:
- API keys
- Database passwords
- JWT secrets
- OAuth tokens

Instead of hardcoding secrets in your code (BAD PRACTICE), you store them in Secrets Manager and retrieve them when needed.

## Prerequisites

Before starting, make sure you have:

1. AWS Account (free tier works)
2. AWS CLI installed
3. Terraform installed (version >= 1.0.0)
4. Basic command line knowledge
5. Text editor (VS Code recommended)

## Step-by-Step Setup

### Step 1: Configure AWS Credentials

First, configure your AWS credentials so Terraform can create resources:

```bash
aws configure
```

You'll be prompted to enter:
- AWS Access Key ID (from your AWS IAM user)
- AWS Secret Access Key (from your AWS IAM user)
- Default region (use us-east-1)
- Output format (press enter for default)

**Test your configuration:**
```bash
aws sts get-caller-identity
```

If this shows your AWS account information, you're ready to proceed.

### Step 2: Understand the Project Structure

```
my-secrets-management-demo/
├── terraform/                    # Infrastructure as Code files
│   ├── main.tf                  # Terraform version requirements
│   ├── provider.tf              # AWS provider configuration
│   ├── secrets.tf               # Secrets Manager resources
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   └── terraform.tfvars.example # Example variable values
├── scripts/                     # Helper scripts
│   └── fetch_secret.sh         # Script to retrieve secrets
└── docs/                        # Documentation
```

### Step 3: Prepare Your Variables

Navigate to the terraform directory and create your variables file:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and add your values:

```hcl
environment = "dev"
region      = "us-east-1"

api_key_value    = "my-api-key-12345"
db_username      = "admin"
db_password      = "MySecurePassword123!"
db_host          = "database.example.com"
db_port          = 5432
db_name          = "appdb"
jwt_secret_value = "my-jwt-secret-key-67890"
```

**IMPORTANT:** Never commit `terraform.tfvars` to Git. It's already in `.gitignore`.

### Step 4: Initialize Terraform

This downloads the necessary providers and prepares your working directory:

```bash
terraform init
```

You should see: "Terraform has been successfully initialized!"

### Step 5: Review What Will Be Created

Before creating resources, review the execution plan:

```bash
terraform plan
```

This shows you what Terraform will create:
- 1 KMS key for encryption
- 1 KMS alias
- 3 secrets (API key, database credentials, JWT secret)
- 3 secret versions (the actual secret values)
- 1 IAM policy for reading secrets

### Step 6: Create the Resources

Apply the Terraform configuration:

```bash
terraform apply
```

Type `yes` when prompted. Terraform will create all resources in AWS.

**What just happened?**
- Created encrypted storage for your secrets
- Stored your secrets securely in AWS
- Created permissions to access those secrets

### Step 7: Verify Secrets Were Created

List all secrets in your AWS account:

```bash
aws secretsmanager list-secrets --region us-east-1
```

You should see three secrets:
- dev/api_key
- dev/database/credentials
- dev/jwt_secret

### Step 8: Retrieve a Secret

Use the helper script to fetch a secret:

```bash
cd ..
./scripts/fetch_secret.sh dev/api_key
```

Or use AWS CLI directly:

```bash
aws secretsmanager get-secret-value \
    --secret-id dev/api_key \
    --region us-east-1 \
    --query 'SecretString' \
    --output text
```

## Understanding the Key Components

### 1. KMS Encryption

Every secret is encrypted using AWS KMS (Key Management Service). This means:
- Secrets are never stored in plain text
- Even AWS administrators can't read your secrets without proper permissions
- Automatic key rotation is enabled for extra security

### 2. Secret Structure

Secrets are stored in JSON format:

```json
{
  "api_key": "your-value",
  "created_at": "2025-12-02T..."
}
```

This allows storing multiple related values in one secret.

### 3. IAM Policies

The `secrets_read` policy grants permission to:
- Read secret values
- Decrypt secrets using KMS
- Describe secret metadata

Attach this policy to users or roles that need to access secrets.

### 4. Tags

All resources are tagged with:
- Environment (dev/staging/prod)
- ManagedBy (Terraform)
- Name and type

Tags help with organization and cost tracking.

## Common Use Cases

### Use Case 1: Database Connection

Instead of hardcoding database credentials:

**BAD:**
```python
db_password = "MyPassword123"  # NEVER DO THIS
```

**GOOD:**
```python
import boto3
import json

client = boto3.client('secretsmanager', region_name='us-east-1')
response = client.get_secret_value(SecretId='dev/database/credentials')
creds = json.loads(response['SecretString'])

db_password = creds['password']
```

### Use Case 2: API Authentication

**BAD:**
```javascript
const apiKey = "abc123";  // NEVER DO THIS
```

**GOOD:**
```javascript
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

const client = new SecretsManagerClient({ region: "us-east-1" });
const response = await client.send(
    new GetSecretValueCommand({ SecretId: "dev/api_key" })
);
const secret = JSON.parse(response.SecretString);
const apiKey = secret.api_key;
```

## Security Best Practices

### 1. Never Commit Secrets
- Keep `terraform.tfvars` out of version control
- Use `.gitignore` to prevent accidental commits
- Never print secrets in logs

### 2. Use Separate Secrets for Different Environments
- dev/api_key
- staging/api_key
- prod/api_key

This prevents accidentally using production secrets in development.

### 3. Principle of Least Privilege
- Only grant access to secrets that are needed
- Use IAM policies to control who can read secrets
- Regularly audit access logs

### 4. Enable Encryption
- Always use KMS encryption (already configured)
- Enable key rotation (already configured)
- Use separate KMS keys for different environments

### 5. Set Recovery Windows
- Secrets aren't immediately deleted
- 7-day recovery window allows restoration
- Prevents accidental permanent deletion

## Troubleshooting

### Problem: "Access Denied" Error

**Solution:** Attach the read policy to your IAM user:
```bash
aws iam attach-user-policy \
    --user-name YOUR_USERNAME \
    --policy-arn $(cd terraform && terraform output -raw secrets_read_policy_arn)
```

### Problem: "Secret Not Found"

**Solution:** Check the secret name and region:
```bash
aws secretsmanager list-secrets --region us-east-1
```

Make sure you're using the exact secret name (e.g., `dev/api_key`).

### Problem: KMS Decryption Error

**Solution:** Ensure you have KMS decrypt permissions. The secrets_read policy includes this, so attach it to your IAM user.

### Problem: Terraform State Conflicts

**Solution:** If you're working in a team, use remote state:
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "secrets/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Cost Information

AWS Secrets Manager pricing (as of 2025):
- $0.40 per secret per month
- $0.05 per 10,000 API calls

**This project costs approximately $2.20/month:**
- 3 secrets x $0.40 = $1.20
- 1 KMS key = $1.00
- API calls (minimal for testing)

## Next Steps

### Level 1: Basic Usage
- [x] Create secrets with Terraform
- [x] Retrieve secrets using CLI
- [x] Understand encryption and permissions

### Level 2: Integration
- [ ] Use secrets in a Python application
- [ ] Use secrets in a Node.js application
- [ ] Integrate with GitHub Actions

### Level 3: Advanced
- [ ] Implement secret rotation
- [ ] Set up cross-account access
- [ ] Configure CloudWatch alarms
- [ ] Add secret versioning strategy

## Cleanup

When you're done experimenting, destroy all resources to avoid charges:

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted. This will delete:
- All secrets
- KMS key (after 10-day waiting period)
- IAM policies

**Note:** Secrets enter a recovery period and aren't immediately deleted. You can restore them within 7 days if needed.

## Additional Resources

- [AWS Secrets Manager Official Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

## Quick Reference Commands

```bash
# List all secrets
aws secretsmanager list-secrets --region us-east-1

# Get a secret value
aws secretsmanager get-secret-value --secret-id dev/api_key --region us-east-1

# Update a secret
aws secretsmanager update-secret --secret-id dev/api_key --secret-string '{"api_key":"new-value"}'

# Terraform commands
terraform init      # Initialize
terraform plan      # Preview changes
terraform apply     # Create resources
terraform destroy   # Delete resources
terraform output    # Show output values
```

## Questions?

If you encounter issues:
1. Check the troubleshooting section above
2. Review AWS CloudTrail logs for API errors
3. Verify your IAM permissions
4. Check that secrets exist in the correct region

Remember: Security is a journey, not a destination. Keep learning and improving your practices!
