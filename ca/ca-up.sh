#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Create the 'certs' and 'certs/rootca-admin' directories in the script's directory
CERTS_DIR="${SCRIPT_DIR}/certs"
ROOTCA_ADMIN_DIR="${CERTS_DIR}/rootca-admin"
echo "${PATH}"

# Check if 'certs' directory exists, if not create it
if [ ! -d "$CERTS_DIR" ]; then
    echo "Creating directory: $CERTS_DIR"
    mkdir -p "$CERTS_DIR"
fi

# Check if 'rootca-admin' directory exists, if not create it
if [ ! -d "$ROOTCA_ADMIN_DIR" ]; then
    echo "Creating directory: $ROOTCA_ADMIN_DIR"
    mkdir -p "$ROOTCA_ADMIN_DIR"
fi

# Step 2: Run Docker Compose to start the CA container using the compose file in the script's directory
echo "Starting CA container with docker-compose..."
docker-compose -f "${SCRIPT_DIR}/docker-compose.yaml" up -d

docker ps

# Step 3: Set FABRIC_CA_HOME environment variable to 'rootca-admin' in the script's directory
echo "Setting FABRIC_CA_HOME to $ROOTCA_ADMIN_DIR"
export FABRIC_CA_HOME="$ROOTCA_ADMIN_DIR"

# Step 4: Enroll the root CA admin
echo "Enrolling root CA admin..."
fabric-ca-client enroll -u http://admin:adminpw@localhost:7054

# Completion message
echo "Root CA admin enrollment completed and certificates stored in $ROOTCA_ADMIN_DIR"
