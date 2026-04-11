#!/bin/bash

# Ensure anvil is running. Wait for it if started in background.
if ! curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://127.0.0.1:8545 > /dev/null; then
    echo "Starting Anvil..."
    anvil &
    echo "Waiting for Anvil to start..."
    sleep 3
fi

# Run deployment
echo "Executing Deployment Script..."
./deploy.sh

# Run Next.js
echo "Starting Next.js..."
cd web
npm install
npm run dev
