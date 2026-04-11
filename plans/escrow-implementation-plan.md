# Escrow DApp - comprehensive Implementation Plan

This document synthesizes all project requirements, scripts, and environmental instructions into a consolidated English plan for building the Escrow DApp efficiently.

## 1. Project Overview & Architecture
An decentralized application (DApp) allowing users to perform peer-to-peer ERC20 token swaps securely using an Escrow smart contract.

**Directory Structure:**
- `sc/`: Foundry project for Smart Contracts.
- `web/`: Next.js 16 frontend with Tailwind CSS v4, initialized with App Router.

**Tech Stack:**
- **Smart Contracts:** Solidity 0.8.x, Foundry, OpenZeppelin Contracts (Ownable, ReentrancyGuard, IERC20).
- **Frontend:** Next.js 16, React 19, TypeScript, Ethers.js v6 / Viem, Tailwind CSS v4.
- **Local Network:** Anvil (running on `http://localhost:8545` with chain ID `31337`).

---

## 2. Smart Contract Development (`sc/src/Escrow.sol`)

### Core Requirements
The contract will facilitate token swaps between two parties.
- Inherit from `Ownable` and `ReentrancyGuard`.
- State variables to track allowed tokens and active/closed operations.

### Key Functions
- `addToken(address)`: Only Owner. Authorizes an ERC20 token for swaps.
- `createOperation(address tokenA, address tokenB, uint256 amountA, uint256 amountB)`: 
  - Transfers `amountA` of `tokenA` from the caller (User 1) to the contract.
  - Registers the operation as "Active".
- `completeOperation(uint256 operationId)`:
  - Caller (User 2) completes the operation.
  - Transfers `amountB` of `tokenB` from User 2 to User 1.
  - Transfers `amountA` of `tokenA` from the contract to User 2.
  - Updates the operation status to "Closed".
  - *Must explicitly prevent the creator from completing their own operation.*
- `cancelOperation(uint256 operationId)`:
  - Only the creator (User 1) can cancel.
  - Returns `amountA` of `tokenA` to User 1.
  - Updates the status to "Cancelled" or removes the operation.
- **View Functions:** `getAllowedTokens()` and `getAllOperations()`.

### Testing
- Comprehensive Foundry tests (`Escrow.t.sol`) covering the happy path (creation, completion), authorization (only owner), edge cases, and reverts.

---

## 3. Automation Scripts
The project relies on existing Bash scripts that we will use and integrate with:
- **`start.sh`**: Start Anvil, run `setup.sh` if needed, install dependencies, and run Next.js (`npm run dev`).
- **`setup.sh` / `setup-simple.sh`**: Deploys the Escrow contract, deploys mock ERC20 tokens (`Token A` and `Token B`), adds tokens to the Escrow, mints 1000 tokens of each to Anvil test accounts, and updates Next.js config (`web/lib/contracts.ts` and `web/.env.local`).
- **`stop.sh`**: Kills Anvil and the Next.js process.

*Test Accounts:*
- Account #0 (Admin): `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`
- Account #1 (User 1): `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
- Account #2 (User 2): `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`

---

## 4. Web Frontend Implementation (`web/`)

### Setup and Scaffolding
- Next.js 16 with App router.
- `web/lib/ethereum.tsx`: Ethereum Context Provider for wallet connection management (auto-reconnect on refresh).
- `web/lib/contracts.ts`: Export ABIs and dynamic contract addresses.

### Components
1. **`ConnectButton.tsx`**:
   - Shows "Connect Wallet". Once connected, abbreviates address (e.g., `0x1234...5678`).
   - Includes disconnect functionality.
2. **`AddToken.tsx`**:
   - Admin-only form to input a token address.
   - Submits tx to `addToken`. Displays the list of currently allowed tokens.
3. **`CreateOperation.tsx`**:
   - Form with dropdowns for Token A and Token B (populated from allowed tokens).
   - Inputs for Amount A and Amount B.
   - Handles the 2-step process: `approve()` Token A -> `createOperation()`.
4. **`OperationsList.tsx`**:
   - Grids/Lists displaying all pending and closed operations.
   - Contains a "Cancel" button if the connected user is the creator.
   - Contains a "Complete Workflow" button for other users (prompts 2-step process: `approve()` Token B -> `completeOperation()`).
   - Auto-refreshes data (e.g., polling every 5s).
5. **`BalanceDebug.tsx`**:
   - Visual component displaying ETH, Token A, and Token B balances for the Escrow Contract, Account 0, Account 1, and Account 2.
   - Crucial for step-by-step verification and debugging.

### Page Layout (`app/page.tsx`)
- **Header**: Title and `ConnectButton`.
- **Main View**: If not connected, show welcome instructions. If connected, show a 3-column layout:
  - Column 1: `AddToken` and `CreateOperation` components.
  - Column 2: `OperationsList`.
  - Column 3: `BalanceDebug`.

### Error Handling & Edge Cases
- Verify RPC connectivity and correct network (Chain ID 31337).
- Handle metamask rejection codes gracefully.
- Prevent "Insufficient allowance" errors by orchestrating `approve` effectively.
- Return empty arrays cleanly on `getAllowedTokens()` or `getAllOperations()` when no items exist.

---

## 5. Development Workflow Outline
1. **Write & Test Smart Contracts**: Implement `Escrow.sol` and test thoroughly via Foundry.
2. **Scripts Integration**: Guarantee the `setup.sh` properly points to `web/lib/contracts.ts` and prepares the environment.
3. **Frontend Base**: Scaffold Next.js, implement ethers.js context, setup Tailwind.
4. **Build Core Components**: Iteratively build out the UI starting with `ConnectButton` up to `OperationsList`.
5. **End-to-End Testing**: Start the local network and verify the UI properly allows the multi-actor flow described in the Spanish README.
