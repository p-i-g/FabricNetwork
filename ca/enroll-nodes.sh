#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# CA URL and default secret
CA_URL="localhost:7054"
DEFAULT_SECRET="secret"

# Array to track unique organizations for which an admin will be created
ORG_ADMINS=()

# Function to register and enroll nodes
register_and_enroll() {
    NODE_NAME=$1
    NODE_TYPE=$2
    ORG_NAME=$(echo "$3" | tr -d '\r')  # Strip \r from ORG_NAME

    # Register the node
    export FABRIC_CA_HOME=${SCRIPT_DIR}/certs/rootca-admin
    echo "Registering ${NODE_NAME}..."
    fabric-ca-client register --id.name "${NODE_NAME}" --id.secret ${DEFAULT_SECRET} --id.type "${NODE_TYPE}" -u ${CA_URL}

    # Set the CA home directory for the node, relative to the script directory
    CA_HOME_DIR="${SCRIPT_DIR}/${NODE_TYPE}s/${ORG_NAME}/${NODE_NAME}"
    export FABRIC_CA_HOME="$CA_HOME_DIR"

    # Create the CA home directory if it doesn't exist
    if [ ! -d "$CA_HOME_DIR" ]; then
        echo "Creating directory: $CA_HOME_DIR"
        mkdir -p "$CA_HOME_DIR"
    fi

    # Enroll the node to generate certificates
    echo "Enrolling ${NODE_NAME}..."
    fabric-ca-client enroll --csr.hosts "${NODE_NAME}" -u "http://${NODE_NAME}:${DEFAULT_SECRET}@${CA_URL}"

    echo "Finished enrolling ${NODE_NAME} and stored files in $CA_HOME_DIR"

    # Check if we have already created and registered an admin for this organization
    if [[ ! " ${ORG_ADMINS[@]} " =~ " ${ORG_NAME} " ]]; then
        # Add this organization to the list of orgs that have an admin
        ORG_ADMINS+=("${ORG_NAME}")

        # Register and create the admin for this organization
        echo "Registering admin for organization ${ORG_NAME}..."
        export FABRIC_CA_HOME=${SCRIPT_DIR}/certs/rootca-admin
        fabric-ca-client register --id.name "admin.${ORG_NAME}.com" --id.secret ${DEFAULT_SECRET} --id.type admin -u ${CA_URL}

        # Create the admin home directory
        ADMIN_HOME_DIR="${SCRIPT_DIR}/${NODE_TYPE}s/${ORG_NAME}/${NODE_NAME}/msp/user"
        export FABRIC_CA_HOME="$ADMIN_HOME_DIR"

        # Create the admin directory if it doesn't exist
        if [ ! -d "$ADMIN_HOME_DIR" ]; then
            echo "Creating directory for admin: $ADMIN_HOME_DIR"
            mkdir -p "$ADMIN_HOME_DIR"
        fi

        # Enroll the admin to generate certificates with the corrected syntax
        echo "Enrolling admin for ${ORG_NAME}..."
        fabric-ca-client enroll --csr.hosts "admin.${ORG_NAME}.com" -u "http://admin.${ORG_NAME}.com:${DEFAULT_SECRET}@${CA_URL}" -M admin
        echo "Finished enrolling admin for ${ORG_NAME} and stored files in $ADMIN_HOME_DIR"
    fi
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

# Loop through each line in the input file
while IFS=":" read -r NODE_NAME NODE_TYPE ORG_NAME; do
    # Skip empty lines
    if [ -z "$NODE_NAME" ] || [ -z "$NODE_TYPE" ] || [ -z "$ORG_NAME" ]; then
        continue
    fi
    # Call the registration/enrollment function
    register_and_enroll "${NODE_NAME}" "${NODE_TYPE}" "${ORG_NAME}"
done < "$INPUT_FILE"

# End of the script
