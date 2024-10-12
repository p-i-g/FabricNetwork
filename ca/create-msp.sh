#!/bin/bash

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

INPUT_FILE=$1

# Arrays to track unique organizations and nodes by type
ORG_LIST=()
NODE_LIST=()

# Process the input file and build lists of nodes and organizations
while IFS=":" read -r NODE_NAME NODE_TYPE ORG_NAME; do
    # Strip \r (carriage return) from ORG_NAME, NODE_NAME, and NODE_TYPE
    NODE_NAME=$(echo "$NODE_NAME" | tr -d '\r')
    NODE_TYPE=$(echo "$NODE_TYPE" | tr -d '\r')
    ORG_NAME=$(echo "$ORG_NAME" | tr -d '\r')

    # Skip empty lines
    if [ -z "$NODE_NAME" ] || [ -z "$NODE_TYPE" ] || [ -z "$ORG_NAME" ]; then
        continue
    fi

    # Add organizations to list
    if [[ ! " ${ORG_LIST[@]} " =~ " ${ORG_NAME} " ]]; then
        ORG_LIST+=("${ORG_NAME}")
    fi

    # Add node to NODE_LIST
    NODE_LIST+=("${NODE_NAME}:${NODE_TYPE}:${ORG_NAME}")
done < "$INPUT_FILE"

# Function to find the first node (orderer or peer) in the organization with a non-empty msp/user directory
find_non_empty_node() {
    ORG_NAME=$1
    for NODE_INFO in "${NODE_LIST[@]}"; do
        IFS=":" read -r NODE_NAME NODE_TYPE NODE_ORG <<< "$NODE_INFO"
        if [[ "${NODE_ORG}" == "${ORG_NAME}" ]]; then
            # Check if msp/user directory is non-empty
            if [ -d "${NODE_TYPE}s/${ORG_NAME}/${NODE_NAME}/msp/user/admin/signcerts" ] && [ "$(ls -A "${NODE_TYPE}s/${ORG_NAME}/${NODE_NAME}/msp/user/admin/signcerts")" ]; then
                echo "${NODE_NAME}:${NODE_TYPE}"  # Return the first non-empty node
                return
            fi
        fi
    done
}

# Step 1: Copy CA and TLS CA certificates for each organization, but only into existing orderers or peers directories
for ORG in "${ORG_LIST[@]}"; do
    echo "Processing organization: ${ORG}"

    # Check if the orderers directory exists and copy the CA and TLS CA certificates if it does
    if [ -d "orderers/${ORG}" ]; then
        echo "Copying CA certificates to orderers..."
        mkdir -p "orderers/${ORG}/msp/cacerts"
        cp ca/server.crt "orderers/${ORG}/msp/cacerts"

        echo "Copying TLS CA certificates to orderers..."
        mkdir -p "orderers/${ORG}/msp/tlscacerts"
        cp tlsca/server.crt "orderers/${ORG}/msp/tlscacerts"
    fi

    # Check if the peers directory exists and copy the CA and TLS CA certificates if it does
    if [ -d "peers/${ORG}" ]; then
        echo "Copying CA certificates to peers..."
        mkdir -p "peers/${ORG}/msp/cacerts"
        cp ca/server.crt "peers/${ORG}/msp/cacerts"

        echo "Copying TLS CA certificates to peers..."
        mkdir -p "peers/${ORG}/msp/tlscacerts"
        cp tlsca/server.crt "peers/${ORG}/msp/tlscacerts"
    fi
done

# Step 2: Handle node-specific operations
for NODE_INFO in "${NODE_LIST[@]}"; do
    IFS=":" read -r NODE_NAME NODE_TYPE ORG_NAME <<< "$NODE_INFO"
    echo "Processing node: ${NODE_NAME} (${NODE_TYPE})"

    # Find the node (either peer or orderer) in this organization with a non-empty msp/user directory
    NON_EMPTY_NODE=$(find_non_empty_node "${ORG_NAME}")

    if [ -n "${NON_EMPTY_NODE}" ]; then
        IFS=":" read -r NON_EMPTY_NODE_NAME NON_EMPTY_NODE_TYPE <<< "${NON_EMPTY_NODE}"
        echo "Found non-empty directory in ${NON_EMPTY_NODE_NAME} (${NON_EMPTY_NODE_TYPE}) for organization ${ORG_NAME}."

        # Create admincerts directories for the node (orderer or peer)
        echo "Creating admincerts directory for ${NODE_NAME} (${NODE_TYPE})..."
        mkdir -p "${NODE_TYPE}s/${ORG_NAME}/${NODE_NAME}/msp/admincerts"
        cp "${NON_EMPTY_NODE_TYPE}s/${ORG_NAME}/${NON_EMPTY_NODE_NAME}/msp/user/admin/signcerts/cert.pem" "${NODE_TYPE}s/${ORG_NAME}/${NODE_NAME}/msp/admincerts/"

        # For peers, also create user-specific admincerts directories
        if [[ "${NODE_TYPE}" == "peer" ]]; then
            echo "Creating user admincerts for peer ${NODE_NAME}..."
            mkdir -p "peers/${ORG_NAME}/${NODE_NAME}/msp/user/admin/admincerts"
            cp "${NON_EMPTY_NODE_TYPE}s/${ORG_NAME}/${NON_EMPTY_NODE_NAME}/msp/user/admin/signcerts/cert.pem" "peers/${ORG_NAME}/${NODE_NAME}/msp/user/admin/admincerts/"
        fi
    else
        echo "No non-empty msp/user directory found for nodes in organization ${ORG_NAME}."
    fi
done

echo "Processing completed!"
