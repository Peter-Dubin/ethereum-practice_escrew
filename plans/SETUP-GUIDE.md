# Escrow DApp - Setup Guide

## Quick Start

### 1. Start Anvil (Terminal 1)
```bash
anvil
```

Keep this terminal running.

### 2. Deploy Contracts (Terminal 2)
```bash
./setup-simple.sh
```

This will:
- Deploy Escrow contract
- Deploy Token A (TKA) and Token B (TKB)
- Mint 1000 TKA + 1000 TKB to 3 test accounts
- Update web configuration with deployed addresses

### 3. Configure MetaMask

#### Add Localhost Network
1. Open MetaMask
2. Click network dropdown (top left)
3. Click "Add Network" → "Add a network manually"
4. Fill in:
   - **Network Name**: Anvil Local
   - **RPC URL**: http://localhost:8545
   - **Chain ID**: 31337
   - **Currency Symbol**: ETH
5. Click "Save"

#### Import Test Account
1. Click account icon (top right)
2. Select "Add account or hardware wallet" → "Import account"
3. Paste one of these private keys (without 0x prefix):
   ```
   ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```
4. Click "Import"

This account will have:
- ~10,000 ETH (for gas)
- 1000 TKA tokens
- 1000 TKB tokens

### 4. Start Web App (Terminal 2)
```bash
cd web
npm run dev
```

Open http://localhost:3000

### 5. Connect Wallet
1. Click "Connect Wallet" button
2. Select MetaMask
3. Approve connection
4. Make sure you're on "Anvil Local" network

## Using the DApp

### Add Token (Admin Only - Account #0)
The first account (0xf39F...) is the owner and can add new tokens to the escrow.

1. Enter token address (e.g., Token A or Token B from deployment-info.txt)
2. Click "Add Token"
3. Approve transaction in MetaMask
4. Wait for confirmation

### Create Operation
1. Enter Token A address (token you're providing)
2. Enter amount of Token A
3. Enter Token B address (token you want)
4. Enter amount of Token B
5. Click "1. Approve Token A" - approve in MetaMask
6. Wait for confirmation
7. Click "2. Create Operation" - approve in MetaMask
8. Wait for confirmation

### Complete Operation (Second User)
1. Import second account to MetaMask:
   ```
   59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
   ```
2. Switch to this account in MetaMask
3. Find an active operation in the list
4. Click "1. Approve Token B"
5. Click "2. Complete"

## Test Accounts

All accounts have 1000 TKA + 1000 TKB:

```
Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

Account #1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

Account #2: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
```

## Troubleshooting

### "Adding..." button stuck
- Check that MetaMask is connected to "Anvil Local" (Chain ID 31337)
- Make sure you approved the transaction in MetaMask popup
- Check browser console (F12) for errors
- Verify you're using Account #0 for admin functions

### "Operation not found" error
- Refresh the page to load latest operations
- Check that the operation ID exists

### Transaction fails
- Make sure you have enough tokens
- Check that tokens are approved before creating/completing operations
- Verify you're connected to the correct network

### Need to reset
```bash
# Stop Anvil (Ctrl+C in Terminal 1)
# Restart Anvil
anvil

# Re-run setup
./setup-simple.sh

# In MetaMask:
# Settings → Advanced → Clear activity tab data
```

## Development

### Build contracts
```bash
cd sc
forge build
```

### Run tests
```bash
cd sc
forge test
```

### Build web
```bash
cd web
npm run build
```
