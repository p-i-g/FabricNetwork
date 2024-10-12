#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# CA URL and default secret
CA_URL="localhost:8054"
ADMIN_CREDENTIALS="http://admin:adminpw@localhost:8054"
DEFAULT_SECRET="secret"

# Function to enroll the admin
enroll_admin() {
    ADMIN_NAME="admin"

    # Set the CA home directory for the admin, relative to the script directory
    export FABRIC_CA_HOME=${SCRIPT_DIR}/certs/roottslca-admin

    # Enroll the admin to generate certificates
    echo "Enrolling admin ${ADMIN_NAME}..."
    fabric-ca-client enroll -u ${ADMIN_CREDENTIALS}

    echo "Finished enrolling admin ${ADMIN_NAME} and stored files in ${FABRIC_CA_HOME}"
}

# Function to register and enroll nodes for TLS certificates
register_and_enroll_tls() {
    NODE_NAME=$1
    NODE_TYPE=$2
    ORG_NAME=$(echo "$3" | tr -d '\r')  # Strip \r from ORG_NAME

    # Register the node for TLS
    export FABRIC_CA_HOME=${SCRIPT_DIR}/certs/roottslca-admin
    echo "Registering ${NODE_NAME} for TLS certificates..."
    fabric-ca-client register --id.name "${NODE_NAME}" --id.secret ${DEFAULT_SECRET} --id.type "${NODE_TYPE}" -u ${CA_URL}

    # Set the CA home directory for the node, relative to the script directory
    CA_HOME_DIR="${SCRIPT_DIR}/${NODE_TYPE}s/${ORG_NAME}/${NODE_NAME}"
    export FABRIC_CA_HOME="$CA_HOME_DIR"

    # Create the CA home directory if it doesn't exist
    if [ ! -d "$CA_HOME_DIR" ]; then
        echo "Creating directory: $CA_HOME_DIR"
        mkdir -p "$CA_HOME_DIR"
    fi

    # Enroll the node for TLS certificates
    echo "Enrolling ${NODE_NAME} for TLS certificates..."
    fabric-ca-client enroll --enrollment.profile tls --csr.hosts "${NODE_NAME}" -u "http://${NODE_NAME}:${DEFAULT_SECRET}@${CA_URL}" -M tls

    echo "Finished enrolling ${NODE_NAME} for TLS certificates and stored files in $CA_HOME_DIR"

    # Rename the generated key file to server.key
    echo "Renaming the key file for ${NODE_NAME}..."
    mv ${CA_HOME_DIR}/tls/keystore/* ${CA_HOME_DIR}/tls/keystore/server.key
    echo "Key file renamed to server.key for ${NODE_NAME}"
}

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

INPUT_FILE=$1

# Check if the input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Input file not found: $INPUT_FILE"
    exit 1
fi

# Enroll the TLS CA admin using the specified admin credentials
enroll_admin

# Loop through each line in the input file
while IFS=":" read -r NODE_NAME NODE_TYPE ORG_NAME; do
    # Skip empty lines
    if [ -z "$NODE_NAME" ] || [ -z "$NODE_TYPE" ] || [ -z "$ORG_NAME" ]; then
        continue
    fi
    # Call the registration/enrollment function for TLS
    register_and_enroll_tls "${NODE_NAME}" "${NODE_TYPE}" "${ORG_NAME}"
done < "$INPUT_FILE"

# End of the script
