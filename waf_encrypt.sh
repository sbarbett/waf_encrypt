#!/bin/bash

# The path to the JSON configuration file
CONFIG_FILE="config.json"

# Parsing JSON to extract values
EMAIL=$(jq -r '.email' $CONFIG_FILE)
UDNS_USERNAME=$(jq -r '.udns_uname' $CONFIG_FILE)
UDNS_PASSWORD=$(jq -r '.udns_pw' $CONFIG_FILE)
UWAF_ID=$(jq -r '.uwaf_id' $CONFIG_FILE)
UWAF_SECRET=$(jq -r '.uwaf_secret' $CONFIG_FILE)

# Export the DNS credentials as environment variables
export ULTRADNS_USERNAME="$UDNS_USERNAME"
export ULTRADNS_PASSWORD="$UDNS_PASSWORD"

# Get a Bearer token
TOKEN_RESPONSE=$(curl -s -L -X POST 'https://auth.appsecportal.com/oauth/token' \
-H 'Content-Type: application/json' \
-d '{
    "client_id": "'"$UWAF_ID"'",
    "client_secret": "'"$UWAF_SECRET"'",
    "audience": "https://api.appsecportal.com/",
    "grant_type": "client_credentials"
}')

# Extract the access token
TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.access_token')
if [ -z "$TOKEN" ]; then
    echo "Failed to retrieve access token"
    exit 1
fi

# Use the current working directory for storing certificates
CERT_PATH="."

# Retrieve array of domains from JSON
DOMAINS=$(jq -c '.domain[]' $CONFIG_FILE)

# Function to generate the unique id
generate_unique_id() {
    local TIMESTAMP=$(date +%s)
    local RANDOM_STRING=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 5)
    local CONCATENATED="${TIMESTAMP: -5}:${RANDOM_STRING}" # Use only the last 5 digits of the timestamp
    echo -n "$CONCATENATED" | base64 | cut -c 1-8 # Keep the base64 string short
}

# Loop through each domain and process it
for DOMAIN in $DOMAINS; do
    DOMAIN=$(echo $DOMAIN | tr -d '"') # Remove quotes from jq output
    echo "Processing certificate for domain: $DOMAIN"

    # Generate the unique id
    UNIQUE_ID=$(generate_unique_id)
    NAME="${DOMAIN}-${UNIQUE_ID}"

    # Ensure the name is within 40 characters
    if [ ${#NAME} -gt 40 ]; then
        NAME="${DOMAIN:0:32}-${UNIQUE_ID}" # Trim the domain part if necessary
    fi

    # Command to run LeGo CLI
    lego --email "$EMAIL" --dns ultradns --domains "$DOMAIN" --path "$CERT_PATH" --key-type rsa4096 --accept-tos run

    # Construct the path to the certificate file and key
    CERT_FILE="${CERT_PATH}/certificates/${DOMAIN}.crt"
    KEY_FILE="${CERT_PATH}/certificates/${DOMAIN}.key"

    # Check if the certificate file and key file exist and read them
    if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
        echo "Certificate for $DOMAIN:"
        cat "$CERT_FILE"

        # Read certificate and key files, escape newlines properly for JSON
        CERT_CONTENT=$(awk '{printf "%s\\n", $0}' "$CERT_FILE")
        KEY_CONTENT=$(awk '{printf "%s\\n", $0}' "$KEY_FILE")

        # Send the certificate and key to the API
        curl -L -X POST 'https://api.appsecportal.com/query' \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer ${TOKEN}" \
        -d '{
          "operationName": "CreateCertificate",
          "variables": {
            "input": {
              "name": "'"$NAME"'",
              "keyPEM": "'"${KEY_CONTENT}"'",
              "certPEM": "'"${CERT_CONTENT}"'"
            }
          },
          "query": "mutation CreateCertificate($input: CreateCertificateInput!) {\n  createCertificate(input: $input) {\n    certificate {\n      id\n      name\n      __typename\n    }\n    __typename\n  }\n}\n"
        }'
    else
        echo "Certificate file or key file not found for $DOMAIN. Please check the log for errors."
    fi

    echo "--------------------------------"
done
