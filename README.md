# Escrow DApp — Trustless P2P ERC20 Token Swap

A decentralized application that lets two parties atomically swap whitelisted ERC20 tokens without a trusted intermediary. Built on Ethereum with Solidity + Foundry on the backend and Next.js + ethers.js on the frontend.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Project Structure](#project-structure)
4. [Smart Contract Reference](#smart-contract-reference)
5. [Frontend Components](#frontend-components)
6. [Test Suite](#test-suite)
7. [Test Accounts](#test-accounts)
8. [Architecture](#architecture)
9. [User Guide](#user-guide)

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Node.js | ≥ 18 | https://nodejs.org |
| Foundry (forge + anvil) | latest | `curl -L https://foundry.paradigm.xyz \| bash && foundryup` |
| MetaMask | latest | Browser extension |

---

## Quick Start

```bash
# 1. Clone the repository
git clone <repo-url>
cd escrow

# 2. Install smart contract dependencies
cd sc && forge install && cd ..

# 3. Install frontend dependencies
cd web && npm install && cd ..
```

**Terminal 1 — start a local Ethereum node:**
```bash
anvil
```

**Terminal 2 — deploy contracts and start the frontend:**
```bash
./deploy.sh          # deploys Escrow + 2 test tokens, mints to test accounts
cd web && npm run dev
```

**Terminal 3 — open the app:**
```
http://localhost:3000
```

**MetaMask configuration:**

| Field | Value |
|-------|-------|
| Network Name | Anvil Local |
| RPC URL | http://localhost:8545 |
| Chain ID | 31337 |
| Currency Symbol | ETH |

Import a test account using one of the private keys from `deployment-info.txt` (generated after deploy).

---

## Project Structure

```
escrow/
├── sc/                          # Smart contracts (Foundry)
│   ├── src/
│   │   ├── Escrow.sol           # Main escrow contract
│   │   └── MockERC20.sol        # Mintable ERC20 for testing
│   ├── test/
│   │   ├── Escrow.t.sol         # Unit tests (37 tests)
│   │   └── EscrowIntegration.t.sol  # Integration tests (11 tests)
│   ├── script/
│   │   └── Deploy.s.sol         # Deployment script
│   └── foundry.toml
├── web/                         # Frontend (Next.js 16)
│   ├── app/
│   │   └── page.tsx             # Main dashboard
│   ├── components/
│   │   ├── ConnectButton.tsx
│   │   ├── AddToken.tsx
│   │   ├── CreateOperation.tsx
│   │   ├── OperationsList.tsx
│   │   └── BalanceDebug.tsx
│   └── lib/
│       ├── contracts.ts         # Deployed contract addresses
│       ├── ethereum.tsx         # Web3 context provider
│       └── *.json               # Contract ABIs
├── docs/
│   ├── ARCHITECTURE.md          # System diagrams (Mermaid)
│   └── USER_GUIDE.md            # Step-by-step usage guide
├── coverage-report.txt          # forge coverage output
├── deploy.sh                    # One-shot deploy script
└── deployment-info.txt          # Generated addresses + private keys
```

---

## Smart Contract Reference

**`Escrow.sol`** — OpenZeppelin Ownable + ReentrancyGuard + SafeERC20

| Function | Access | Description | Reverts When |
|----------|--------|-------------|--------------|
| `addToken(address token)` | `onlyOwner` | Whitelists an ERC20 token for use in swaps | Zero address; already whitelisted |
| `createOperation(tokenA, tokenB, amountA, amountB)` | Public | Deposits `amountA` of `tokenA` into escrow and lists a swap offer | Either token not whitelisted; either amount is zero; insufficient allowance |
| `completeOperation(uint256 id)` | Public | Caller provides `amountB` of `tokenB`; receives `amountA` of `tokenA` | Invalid ID; not Active; caller is the creator; insufficient allowance |
| `cancelOperation(uint256 id)` | Public | Creator reclaims their deposited `tokenA` | Invalid ID; not Active; caller is not creator |
| `getAllowedTokens()` | View | Returns the full whitelist of token addresses | — |
| `getAllOperations()` | View | Returns all operations (all statuses) | — |

**Events:**

| Event | Emitted When |
|-------|-------------|
| `TokenAdded(address indexed token)` | Owner adds a token |
| `OperationCreated(uint256 indexed id, address indexed creator, ...)` | New swap created |
| `OperationCompleted(uint256 indexed id, address indexed completer)` | Swap fulfilled |
| `OperationCancelled(uint256 indexed id)` | Swap cancelled by creator |

**Operation states:** `Active → Closed` (via `completeOperation`) or `Active → Cancelled` (via `cancelOperation`)

---

## Frontend Components

| Component | File | Purpose |
|-----------|------|---------|
| **ConnectButton** | `components/ConnectButton.tsx` | MetaMask connect / disconnect; shows truncated address |
| **AddToken** | `components/AddToken.tsx` | Admin panel to whitelist existing tokens or deploy + register new MockERC20s |
| **CreateOperation** | `components/CreateOperation.tsx` | Select token pair + amounts, then approve + create in two transactions |
| **OperationsList** | `components/OperationsList.tsx` | Displays all operations with status badges; surfaces Complete / Cancel actions |
| **BalanceDebug** | `components/BalanceDebug.tsx` | Live balance grid for the Escrow contract + all three test accounts |

**Tech stack:** Next.js 16 · React 19 · ethers.js 6 · TypeScript · Tailwind CSS 4

---

## Test Suite

### Running tests

```bash
cd sc

# Run all tests (verbose)
forge test -v

# Run only unit tests
forge test --match-path "test/Escrow.t.sol" -v

# Run only integration tests
forge test --match-path "test/EscrowIntegration.t.sol" -v
```

### Coverage

```bash
cd sc
forge coverage --report summary
```

**Results (`src/Escrow.sol`):**

| Metric | Coverage |
|--------|----------|
| Lines | 100% (36/36) |
| Statements | 100% (30/30) |
| Branches | 100% (24/24) |
| Functions | 100% (6/6) |

Full report: [coverage-report.txt](coverage-report.txt)

### Test breakdown

| File | Tests | What's covered |
|------|-------|---------------|
| `test/Escrow.t.sol` | 37 | Happy path, all reverts, all events, state transitions, fuzz |
| `test/EscrowIntegration.t.sol` | 11 | End-to-end workflows, mixed ops, edge amounts, multi-user |
| `test/Counter.t.sol` | 2 | Boilerplate Foundry counter example |
| **Total** | **50** | |

---

## Test Accounts

Three deterministic Anvil accounts are pre-funded and used throughout the project.

| Role | Address |
|------|---------|
| Owner / Admin | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` |
| User 1 | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` |
| User 2 | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` |

Private keys are written to `deployment-info.txt` after running `deploy.sh`.
All accounts start with 10 000 ETH (Anvil default) and 1 000 of each test token.

---

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for system overview, contract state machine, and transaction sequence diagrams.

---

## User Guide

See [docs/USER_GUIDE.md](docs/USER_GUIDE.md) for step-by-step instructions on connecting a wallet, adding tokens, creating and completing swaps, and troubleshooting common issues.
