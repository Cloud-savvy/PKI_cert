#!/bin/bash
# Variables
VAULT_ADDR="http://34.230.183.157:8200"
VAULT_TOKEN="hvs.ReUebAxP1CY3HT0VWCdSa3jZ"
ROLE_NAME="balaji-role"
COMMON_NAME="test.balajipki.com"
K8S_SECRET_NAME="balaji-cert"
NAMESPACE="default"

# Export Vault token
export VAULT_ADDR VAULT_TOKEN

# Check certificate expiry
if [ -f cert.crt ]; then
    EXPIRY_DATE=$(openssl x509 -in cert.crt -noout -enddate | cut -d= -f2)
    CURRENT_DATE=$(date -u +'%b %d %H:%M:%S %Y GMT')

    echo "Certificate Expiry: $EXPIRY_DATE"
    echo "Current Date: $CURRENT_DATE"

    if [[ "$EXPIRY_DATE" > "$CURRENT_DATE" ]]; then
        echo "Certificate is still valid."
        exit 0
    fi
fi

echo "Certificate is expired or not found. Renewing..."

# Renew the certificate
vault write -format=json pki/issue/$ROLE_NAME \
    common_name="$COMMON_NAME" > cert.json

# Extract certificate and key
jq -r '.data.certificate' cert.json > cert.crt
jq -r '.data.private_key' cert.json > cert.key
jq -r '.data.issuing_ca' cert.json > ca.crt
