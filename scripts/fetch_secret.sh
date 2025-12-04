#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REGION="${2:-us-east-1}"
SECRET_NAME="${1:-}"

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

if [ -z "$SECRET_NAME" ]; then
    print_error "Secret name is required"
    echo "Usage: $0 <secret-name> [region]"
    echo "Example: $0 dev/api_key us-east-1"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure'"
    exit 1
fi

print_info "Fetching secret: $SECRET_NAME from region: $REGION"

SECRET_VALUE=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$REGION" \
    --query 'SecretString' \
    --output text 2>&1)

if [ $? -eq 0 ]; then
    print_info "Secret retrieved successfully"
    
    if echo "$SECRET_VALUE" | jq . &> /dev/null; then
        print_info "Secret value (JSON formatted):"
        echo "$SECRET_VALUE" | jq .
    else
        print_info "Secret value:"
        echo "$SECRET_VALUE"
    fi
else
    print_error "Failed to retrieve secret"
    echo "$SECRET_VALUE"
    exit 1
fi

print_warning "Remember: Never log or expose secrets in production!"
