#!/bin/bash
export RPC_URL="http://127.0.0.1:8545"
export PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

cd sc
echo "Running Deployment Script..."
OUT=$(forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast)
echo "$OUT"

ESCROW_ADDRESS=$(echo "$OUT" | awk -F'=' '/deploy_escrow=/{print $2}' | xargs)
TOKEN_A_ADDRESS=$(echo "$OUT" | awk -F'=' '/deploy_tokenA=/{print $2}' | xargs)
TOKEN_B_ADDRESS=$(echo "$OUT" | awk -F'=' '/deploy_tokenB=/{print $2}' | xargs)

if [ -z "$ESCROW_ADDRESS" ]; then
    echo "Failed to deploy!"
    exit 1
fi

cd ..
mkdir -p web/lib
cat > web/lib/contracts.ts <<EOF
export const ESCROW_ADDRESS = "$ESCROW_ADDRESS" as const;
export const TOKEN_A_ADDRESS = "$TOKEN_A_ADDRESS" as const;
export const TOKEN_B_ADDRESS = "$TOKEN_B_ADDRESS" as const;
EOF

cat > deployment-info.txt <<EOF
Escrow: $ESCROW_ADDRESS
TokenA: $TOKEN_A_ADDRESS
TokenB: $TOKEN_B_ADDRESS
EOF

cp sc/out/Escrow.sol/Escrow.json web/lib/Escrow.json
cp sc/out/MockERC20.sol/MockERC20.json web/lib/MockERC20.json

echo "Deployment complete."
