#!/bin/bash

# Variables

VAULT_ADDR="http://34.230.183.157:8200"
VAULT_TOKEN="hvs.ReUebAxP1CY3HT0VWCdSa3jZ"
ROLE_NAME="balaji-role"
COMMON_NAME="test.balajipki.com"
K8S_SECRET_NAME="balaji-cert"
NAMESPACE="default"
RENEW_THRESHOLD_DAYS=15

# Export Vault token (Ensure the token is securely stored)
export VAULT_ADDR VAULT_TOKEN

# Check if certificate exists and if it is valid
if [ -f cert.crt ]; then
    # Extract expiry date from the certificate
    EXPIRY_DATE=$(openssl x509 -in cert.crt -noout -enddate | cut -d= -f2)
    
    # Convert expiry date and current date to a comparable format
    EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
    CURRENT_TIMESTAMP=$(date -u +%s)
    RENEW_THRESHOLD_TIMESTAMP=$(date -d "+$RENEW_THRESHOLD_DAYS days" +%s)

    echo "Certificate Expiry: $EXPIRY_DATE"
    echo "Current Date: $(date -u +'%b %d %H:%M:%S %Y GMT')"

    # Compare expiry date and current date
    if [ "$EXPIRY_TIMESTAMP" -gt "$RENEW_THRESHOLD_TIMESTAMP" ]; then
        echo "Certificate is still valid and has more than $RENEW_THRESHOLD_DAYS days remaining."
        exit 0
    fi
fi

echo "Certificate is expired or has less than $RENEW_THRESHOLD_DAYS days remaining. Renewing..."

# Renew the certificate using Vault PKI endpoint
vault write -format=json pki/issue/$ROLE_NAME \
    common_name="$COMMON_NAME" \
    > cert.json

# Check if the Vault command was successful
if [ $? -ne 0 ]; then
    echo "Error renewing certificate from Vault."
    exit 1
fi

# Extract certificate, private key, and issuing CA from the Vault response
jq -r '.data.certificate' cert.json > cert.crt
jq -r '.data.private_key' cert.json > cert.key
jq -r '.data.issuing_ca' cert.json > ca.crt

# Check if files are created successfully
if [ ! -f cert.crt ] || [ ! -f cert.key ] || [ ! -f ca.crt ]; then
    echo "Error extracting the certificate files."
    exit 1
fi

echo "Certificate renewed successfully."
