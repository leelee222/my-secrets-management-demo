### Secure Secret Management + Compliance Automation in a DevSecOps Pipeline

*A hands-on project demonstrating secure secret handling using AWS Secrets Manager, Terraform, and GitHub Actions.*

---

## **Project Overview**

This project implements a **secure secret management workflow** using an AWS-native approach.
The goal is to store, retrieve, and validate secrets *without ever exposing them*, while also enforcing compliance and security checks through CI/CD.

This is **Week 9** of my *3-month DevSecOps learning roadmap*, focusing on:

* Secure secret storage
* Secret injection in CI/CD
* Pipeline safety
* Infrastructure-as-Code compliance
* Automating security controls

It demonstrates real DevSecOps practices used in modern cloud environments.

---

## **Features**

### **Secrets stored securely in AWS Secrets Manager**

* API keys, DB passwords, JWT secrets
* Versioning support
* No plaintext exposure

### **Terraform-based secret provisioning**

* Secrets and metadata created via IaC
* Outputs masked
* No manual AWS Console configuration

### **Secure retrieval in CI/CD (GitHub Actions)**

* OIDC or AWS credentials
* Secrets never printed in logs
* Pipeline fails if secrets are mishandled

### **Compliance Enforcement with Checkov**

* Validates Terraform against CIS benchmarks
* Prevents insecure deployments
* Detects misconfigurations early

---

## **Tech Stack**

| Category   | Tools                      |
| ---------- | -------------------------- |
| Cloud      | AWS (Secrets Manager, IAM) |
| IaC        | Terraform                  |
| CI/CD      | GitHub Actions             |
| Compliance | Checkov                    |
| Scripting  | Bash                       |

---

## **Project Structure**

```
secrets-management-demo/
 ├── terraform/
 │    ├── main.tf
 │    ├── provider.tf
 │    ├── secrets.tf
 │    ├── variables.tf
 │    └── outputs.tf
 ├── pipeline/
 │    └── secrets-pipeline.yml
 ├── scripts/
 │    └── fetch_secret.sh
 ├── docs/
 │    └── secrets_workflow.md
 └── README.md
```

---

## **How It Works**

### **Store secrets using Terraform**

Example:

```hcl
resource "aws_secretsmanager_secret" "api_key" {
  name = "dev/api_key"
}

resource "aws_secretsmanager_secret_version" "api_key_value" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = "super_secret_api_key_123"
}
```

---

### **Retrieve secrets securely in GitHub Actions**

```yaml
- name: Retrieve Secret
  id: secret
  run: |
    SECRET=$(aws secretsmanager get-secret-value \
      --secret-id dev/api_key \
      --query SecretString \
      --output text)
    echo "secret=$SECRET" >> $GITHUB_OUTPUT
```

**Note:** The secret is never printed to logs.
GitHub masks the value automatically.

---

### **Run compliance scans**

```yaml
- name: Run Checkov
  uses: bridgecrewio/checkov-action@v12
  with:
    directory: ./terraform
    soft_fail: false
```

If Terraform code is insecure → pipeline fails.

---

## **Local Testing**

To retrieve your secret locally:

```bash
chmod +x scripts/fetch_secret.sh
./scripts/fetch_secret.sh
```

---

## **Documentation**

Full workflow explanation is available in:

```
/docs/secrets_workflow.md
```

Includes:

* IAM permissions
* Terraform lifecycle
* CI/CD security patterns
* What is and isn’t allowed

---

## **What This Project Demonstrates**

* Secure secret handling in cloud environments
* Zero trust CI/CD principles
* IaC security compliance
* Preventing secret leaks in logs
* Automated governance using Checkov
* Real DevSecOps skills suitable for production workflows

This project is part of my **Advanced DevSecOps Month (Month 3)** and lays the foundation for:

* Monitoring & logging automation
* Vulnerability management
* Full DevSecOps portfolio build-out

---

## **Want to Connect?**

I'm actively building my DevSecOps skillset — if you're hiring, collaborating, or curious about the workflow, feel free to reach out.