# Define shell scripts and input file
CA_UP_SCRIPT=./ca-up.sh
ENROLL_NODES_SCRIPT=./enroll-nodes.sh
REGISTER_TLS_CERTS_SCRIPT=./register_tsl_certs.sh
CREATE_MSP_SCRIPT=./create-msp.sh  # New script for creating MSP
INPUT_FILE=../nodes  # Input file to be passed to the scripts

# Default target: Call shell scripts in the correct order
all: ca-up enroll-nodes register-tls create-msp

# Step 1: Run ca-up.sh
ca-up:
	@echo "Starting CA services..."
	@bash $(CA_UP_SCRIPT)

# Step 2: Run enroll-nodes.sh with input file
enroll-nodes: ca-up
	@echo "Enrolling nodes using input file $(INPUT_FILE)..."
	@bash $(ENROLL_NODES_SCRIPT) $(INPUT_FILE)

# Step 3: Run register-tls-certs.sh with input file
register-tls: enroll-nodes
	@echo "Registering TLS certificates using input file $(INPUT_FILE)..."
	@bash $(REGISTER_TLS_CERTS_SCRIPT) $(INPUT_FILE)

# Step 4: Run create-msp.sh with input file
create-msp: register-tls
	@echo "Creating MSP using input file $(INPUT_FILE)..."
	@bash $(CREATE_MSP_SCRIPT) $(INPUT_FILE)

# Clean target: Remove all directories but keep files directly under this directory
clean:
	@echo "Cleaning up directories..."
	@find . -mindepth 1 -type d -exec rm -rf {} +
	@docker-compose -f docker-compose.yaml down --volume

# Phony targets to avoid naming conflicts
.PHONY: all ca-up enroll-nodes register-tls create-msp clean
