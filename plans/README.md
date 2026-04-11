# Escrow DApp

A decentralized escrow application for secure ERC20 token swaps on Ethereum.

## Quick Start (Automated)

The easiest way to get started:

```bash
# Make sure you have Anvil installed (part of Foundry)
./start.sh
```

This script will:
- Check if Anvil is running (starts it if not)
- Deploy all contracts (Escrow + 2 mock tokens)
- Add tokens to the escrow contract
- Mint test tokens to Anvil accounts
- Update web configuration with contract addresses
- Create `.env.local` with all environment variables
- Start the web application

**Alternative: Manual setup only**
```bash
./setup.sh  # Deploy contracts without starting servers
```

**Stop all services:**
```bash
./stop.sh
```

**View available accounts:**
```bash
./accounts.sh  # Show all Anvil test accounts and private keys
source ./accounts.sh  # Load as environment variables
```

## 🔑 Test Accounts

After running `./setup.sh` or `./start.sh`, you'll have access to 3 pre-funded accounts.

See [ACCOUNTS.md](ACCOUNTS.md) for detailed information about accessing and using the test accounts.

Quick access:
- All accounts have 10,000 ETH for gas
- All accounts have 1,000 TKA and 1,000 TKB tokens
- Private keys are in `deployment-info.txt` and `web/.env.local`

## Project Structure

```
.
├── sc/           # Smart contracts (Foundry)
│   ├── src/      # Contract source files
│   ├── test/     # Contract tests
│   └── script/   # Deployment scripts
└── web/          # Frontend (Next.js)
    ├── app/      # Next.js pages
    ├── components/ # React components
    └── lib/      # Configuration and utilities
```

## Features

### Smart Contract Features

- **Multi-token Support**: Admin can add multiple ERC20 tokens
- **Create Operations**: Users can create escrow operations specifying:
  - Token A (offering)
  - Token B (requesting)
  - Amount A and Amount B
- **Complete Operations**: Other users can fulfill escrow operations
- **Cancel Operations**: Creators can cancel their operations and retrieve tokens
- **Security**: Uses OpenZeppelin's ReentrancyGuard and Ownable

### Web Features

- **Wallet Connection**: Connect via MetaMask or other injected wallets
- **Admin Panel**: Add new tokens to the escrow contract
- **Create Operations**: User-friendly interface to create escrow swaps
- **View Operations**: Browse all active and closed operations
- **Complete Operations**: Two-step process (approve + complete)
- **Cancel Operations**: Creators can cancel their own operations

## Getting Started

### Prerequisites

- Node.js 18+
- Foundry (for smart contracts)
- MetaMask or compatible Web3 wallet

### Smart Contracts Setup

1. Navigate to the smart contracts directory:
```bash
cd sc
```

2. Install dependencies:
```bash
forge install
```

3. Compile contracts:
```bash
forge build
```

4. Run tests:
```bash
forge test
```

5. Start local blockchain (Anvil):
```bash
anvil
```

6. Deploy contracts (in another terminal):
```bash
forge script script/Escrow.s.sol:EscrowScript --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY> --broadcast
```

7. Note the deployed contract address and update it in `web/lib/contracts.ts`

### Web Application Setup

1. Navigate to the web directory:
```bash
cd web
```

2. Install dependencies:
```bash
npm install
```

3. Update the contract address in `lib/contracts.ts`:
```typescript
export const ESCROW_ADDRESS = '0xYourDeployedAddress' as const;
```

4. Run development server:
```bash
npm run dev
```

5. Open [http://localhost:3000](http://localhost:3000)

## Usage Flow

### For Admin

1. Connect your wallet
2. Add supported ERC20 tokens using the "Add Token" form

### For User 1 (Creating Operation)

1. Connect your wallet
2. Use the "Create Operation" form:
   - Enter Token A address (token you're offering)
   - Enter Amount A
   - Enter Token B address (token you want)
   - Enter Amount B
3. Click "1. Approve Token A" and confirm transaction
4. Click "2. Create Operation" and confirm transaction
5. Your operation appears in the operations list

### For User 2 (Completing Operation)

1. Connect your wallet
2. Browse operations in the operations list
3. Find an active operation you want to complete
4. Click "1. Approve Token B" and confirm transaction
5. Click "2. Complete Operation" and confirm transaction
6. Tokens are swapped:
   - You receive Token A
   - Creator receives Token B
   - Operation is marked as closed

### Cancelling an Operation

If you created an operation and want to cancel it:
1. Find your operation in the list
2. Click "Cancel Operation"
3. Confirm the transaction
4. Your tokens are returned

## Testing with Mock Tokens

For local testing, you can deploy mock ERC20 tokens:

1. The `MockERC20.sol` contract is included in the `sc/src` directory
2. Deploy two mock tokens:
```bash
forge create src/MockERC20.sol:MockERC20 --constructor-args "Token A" "TKA" --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY>
forge create src/MockERC20.sol:MockERC20 --constructor-args "Token B" "TKB" --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY>
```
3. Add these token addresses to the escrow contract via the web interface
4. Use these addresses when creating operations

## Contract Addresses

After deployment, update these addresses in your configuration:

- **Escrow Contract**: Update in `web/lib/contracts.ts`
- **ERC20 Tokens**: Add via the admin interface in the web app

## Technology Stack

### Smart Contracts
- Solidity ^0.8.13
- Foundry
- OpenZeppelin Contracts

### Frontend
- Next.js 16
- React 19
- TypeScript
- Tailwind CSS v4
- Wagmi (Web3 React hooks)
- Viem (Ethereum library)
- TanStack Query (React Query)

## Security Considerations

- All token transfers use OpenZeppelin's IERC20 interface
- ReentrancyGuard protects against reentrancy attacks
- Ownable pattern restricts admin functions
- Users must approve tokens before operations
- Operations can only be completed by users other than the creator

## License

MIT
