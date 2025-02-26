#!/bin/bash

# Load environment variables
source .env

# Check if private key is set
if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set in .env file"
    exit 1
fi

# Deploy to Arbitrum Sepolia
forge script script/FactoryDeployer.s.sol:FactoryDeployer \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --verify \
    --broadcast \
    --chain-id $CHAIN_ID \
    -vvvv 