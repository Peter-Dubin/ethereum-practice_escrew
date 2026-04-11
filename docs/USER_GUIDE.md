# User Guide

This guide walks through every feature of the Escrow DApp step by step.

---

## Introduction

The Escrow DApp lets two parties swap ERC20 tokens directly with each other — no middleman, no trust required. One user deposits the token they're offering; the other user fulfills the swap by providing the requested token. The smart contract guarantees the exchange is atomic: either both sides receive their tokens or nothing happens.

---

## 1. Setup and MetaMask Configuration

### Add the local Anvil network to MetaMask

1. Open MetaMask → click the network selector at the top → **Add a custom network**
2. Fill in:

   | Field | Value |
   |-------|-------|
   | Network Name | Anvil Local |
   | New RPC URL | `http://localhost:8545` |
   | Chain ID | `31337` |
   | Currency Symbol | `ETH` |

3. Click **Save**

### Import a test account

After running `./deploy.sh`, open `deployment-info.txt` in the project root. You'll find three private keys. Import any of them into MetaMask:

1. MetaMask → click your account icon → **Add account or hardware wallet** → **Import account**
2. Paste one of the private keys → **Import**

| Account | Address | Role |
|---------|---------|------|
| Account 0 | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | Contract owner / admin |
| Account 1 | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | User 1 |
| Account 2 | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | User 2 |

All accounts start with 10 000 ETH and 1 000 of each test token.

---

## 2. Connect Your Wallet

1. Open `http://localhost:3000` in your browser
2. Click the **Connect Wallet** button in the top-right area of the header
3. MetaMask will ask you to approve the connection — click **Connect**
4. Your abbreviated address appears in the header (e.g. `0xf39F...266`)

To disconnect, click your address → **Disconnect**.

---

## 3. Add Token (Admin Only)

This panel is only visible when you are connected with the **owner account** (`0xf39F...266`). It allows you to whitelist ERC20 tokens for use in swaps.

### Method A: Register an existing ERC20

1. Paste the token contract address into the **Token Address** field
2. Click **Add Token**
3. The token appears in the **Approved Registry** list below

### Method B: Deploy a new test token and register it

1. Enter a **Token Name** (e.g. `Gold`)
2. Enter a **Token Symbol** (e.g. `GLD`)
3. Click **Deploy & Register**
4. MetaMask shows two transactions: deploy the token contract, then register it with the escrow
5. After both confirm, the new token appears in the registry and 1 000 units are minted to each of the three test accounts

---

## 4. Create an Operation (Offer a Swap)

1. Connect with any account (User 1, User 2, or Owner)
2. In the **Create Operation** panel:
   - **Token A** — select the token you are offering from the dropdown
   - **Token B** — select the token you want in return (must be different from Token A)
   - **Amount A** — how many tokens you are offering
   - **Amount B** — how many tokens you require in return
3. Click **Submit Transaction**
4. MetaMask prompts you for two transactions in sequence:
   - **Approve** — grants the Escrow contract permission to pull your tokens
   - **Create Operation** — deposits your tokens and registers the swap offer
5. After both transactions confirm, the new operation appears in the **Operations Book** with status `ACTIVE`

---

## 5. Complete a Trade (Fulfill a Swap)

You cannot complete an operation that you created yourself.

1. Switch to a **different account** in MetaMask (one that is not the creator of the operation you want to fill)
2. In the **Operations Book**, find an `ACTIVE` operation
3. Click **Complete Trade** on that operation
4. MetaMask prompts two transactions:
   - **Approve** — grants Escrow permission to pull the Token B amount from your wallet
   - **Complete Operation** — executes the atomic swap
5. After confirmation:
   - You receive the Token A amount
   - The creator receives the Token B amount
   - The operation status changes to `CLOSED`

---

## 6. Cancel an Operation

Only the **original creator** of an operation can cancel it.

1. Connect with the account that created the operation
2. In the **Operations Book**, find your `ACTIVE` operation — it shows a **Cancel Operation** button
3. Click **Cancel Operation**
4. MetaMask shows one transaction — confirm it
5. After confirmation:
   - Your Token A is refunded to your wallet
   - The operation status changes to `CANCELLED`

---

## 7. Ledger Debug Panel

The **Ledger Debug** panel at the bottom of the dashboard shows real-time token and ETH balances for:

- The **Escrow contract** itself (tokens held in escrow)
- **Account 0** (Owner)
- **Account 1** (User 1)
- **Account 2** (User 2)

Balances refresh automatically every **5 seconds**. Click the refresh icon to force an immediate update.

Use this panel to verify that tokens moved correctly after creating, completing, or cancelling operations.

---

## 8. Troubleshooting

### "Nonce too high" or transactions fail silently in MetaMask

This happens when Anvil is restarted but MetaMask still remembers old transaction counts.

**Fix:** MetaMask → Settings → Advanced → **Clear activity tab data**

### My token doesn't appear in MetaMask's Assets tab

MetaMask doesn't auto-detect custom tokens on local networks.

**Fix:** MetaMask → Assets → **Import tokens** → paste the token contract address from `deployment-info.txt` or the Approved Registry in the DApp.

### Wrong network / transactions going to mainnet

Check the MetaMask network selector at the top — it must show **Anvil Local** (Chain ID 31337).

**Fix:** Switch to the Anvil Local network. If it doesn't exist, follow [Section 1](#1-setup-and-metamask-configuration) to add it.

### The frontend shows no tokens in the dropdowns

The token list is fetched from the Escrow contract. If the list is empty, either:
- Anvil isn't running (`anvil` in a terminal)
- The deploy script hasn't run yet (`./deploy.sh`)
- The contract address in `web/lib/contracts.ts` doesn't match the current deployment (re-run `./deploy.sh`)

### "Transaction failed" with no message

Check that:
1. You have enough of the token you're depositing (check the Ledger Debug panel)
2. You approved before trying to create/complete (the DApp handles this automatically, but MetaMask occasionally rejects the approval if gas estimation fails — try again)
3. You are not trying to complete your own operation (the contract rejects this)
