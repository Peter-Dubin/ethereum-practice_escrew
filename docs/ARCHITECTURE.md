# Architecture

This document describes the system architecture of the Escrow DApp using diagrams.

---

## 1. System Overview

The DApp has two layers: a Next.js browser frontend that communicates with the user's MetaMask wallet, which in turn submits transactions to smart contracts deployed on an Anvil local Ethereum node.

```mermaid
graph TB
    subgraph Browser
        UI["Next.js 16 Frontend\n(React 19 + Tailwind CSS)"]
        MM["MetaMask Wallet\n(ethers.js v6 BrowserProvider)"]
    end

    subgraph "Anvil / EVM Network (Chain ID 31337)"
        EC["Escrow Contract\n(Ownable · ReentrancyGuard · SafeERC20)"]
        TA["Token A — MockERC20\n(ERC20 standard)"]
        TB["Token B — MockERC20\n(ERC20 standard)"]
    end

    UI -- "ethers.js v6\nread calls / tx signing" --> MM
    MM -- "JSON-RPC\neth_call / eth_sendTransaction" --> EC
    EC -- "safeTransferFrom\n(deposit)" --> TA
    EC -- "safeTransferFrom\n(deposit)" --> TB
    EC -- "safeTransfer\n(payout)" --> TA
    EC -- "safeTransfer\n(payout)" --> TB
```

---

## 2. Operation State Machine

An operation begins as `Active` when created. It can only transition once — either to `Closed` (successfully completed) or `Cancelled` (withdrawn by creator). Both terminal states are final.

```mermaid
stateDiagram-v2
    [*] --> Active : createOperation()\nCreator deposits tokenA

    Active --> Closed : completeOperation()\nCalled by non-creator\nwho provides tokenB

    Active --> Cancelled : cancelOperation()\nCalled by creator\ntokenA refunded

    Closed --> [*]
    Cancelled --> [*]
```

---

## 3. createOperation — Transaction Sequence

```mermaid
sequenceDiagram
    actor U1 as User 1 (Creator)
    participant TA as Token A Contract
    participant E as Escrow Contract

    U1->>TA: approve(escrow, amountA)
    TA-->>U1: ✓ allowance set

    U1->>E: createOperation(tokenA, tokenB, amountA, amountB)
    E->>E: require: tokenA whitelisted
    E->>E: require: tokenB whitelisted
    E->>E: require: amountA > 0
    E->>E: require: amountB > 0
    E->>E: push Operation{Active, id=N}
    E->>TA: safeTransferFrom(user1 → escrow, amountA)
    TA-->>E: ✓ transferred
    E-->>U1: emit OperationCreated(id, creator, tokenA, tokenB, amountA, amountB)
```

---

## 4. completeOperation — Transaction Sequence

```mermaid
sequenceDiagram
    actor U2 as User 2 (Completer)
    actor U1 as User 1 (Creator)
    participant TB as Token B Contract
    participant TA as Token A Contract
    participant E as Escrow Contract

    U2->>TB: approve(escrow, amountB)
    TB-->>U2: ✓ allowance set

    U2->>E: completeOperation(operationId)
    E->>E: require: operationId valid
    E->>E: require: status == Active
    E->>E: require: caller != creator
    E->>E: set status = Closed
    E->>TB: safeTransferFrom(user2 → user1, amountB)
    TB-->>U1: ✓ user1 receives tokenB
    E->>TA: safeTransfer(user2, amountA)
    TA-->>U2: ✓ user2 receives tokenA
    E-->>U2: emit OperationCompleted(id, completer)
```

---

## 5. cancelOperation — Transaction Sequence

```mermaid
sequenceDiagram
    actor U1 as User 1 (Creator)
    participant TA as Token A Contract
    participant E as Escrow Contract

    U1->>E: cancelOperation(operationId)
    E->>E: require: operationId valid
    E->>E: require: status == Active
    E->>E: require: caller == creator
    E->>E: set status = Cancelled
    E->>TA: safeTransfer(user1, amountA)
    TA-->>U1: ✓ tokenA refunded
    E-->>U1: emit OperationCancelled(id)
```

---

## 6. Frontend Component Architecture

The `EthereumProvider` context wraps the entire application, supplying the connected wallet address, provider, and signer to all child components via the `useEthereum()` hook. Each component polls the contracts independently.

```mermaid
graph TD
    PG["app/page.tsx\n(Dashboard layout)"]
    EP["EthereumProvider\nlib/ethereum.tsx\n(BrowserProvider · signer · address)"]

    CB["ConnectButton\nMetaMask connect/disconnect"]
    AT["AddToken\nAdmin: whitelist or deploy tokens\nPolls: 15s"]
    CO["CreateOperation\nApprove + createOperation\nPolls: 10s"]
    OL["OperationsList\nComplete / Cancel actions\nPolls: 5s"]
    BD["BalanceDebug\nETH + token balances\nPolls: 5s"]

    EC["Escrow Contract"]
    ERC["ERC20 Contracts\n(TKA, TKB, ...)"]

    PG --> EP
    EP --> CB
    EP --> AT
    EP --> CO
    EP --> OL
    EP --> BD

    AT -->|"addToken()\ngetAllowedTokens()"| EC
    AT -->|"deploy MockERC20\nmint()"| ERC

    CO -->|"approve()"| ERC
    CO -->|"createOperation()\ngetAllowedTokens()"| EC

    OL -->|"approve()"| ERC
    OL -->|"completeOperation()\ncancelOperation()\ngetAllOperations()"| EC

    BD -->|"balanceOf()\ngetAllowedTokens()"| ERC
    BD -->|"getAllowedTokens()"| EC
```

---

## 7. Smart Contract Inheritance

```mermaid
classDiagram
    class Escrow {
        +mapping allowedTokens
        +address[] allowedTokensList
        +Operation[] operations
        +addToken(address)
        +createOperation(address, address, uint256, uint256)
        +completeOperation(uint256)
        +cancelOperation(uint256)
        +getAllowedTokens() address[]
        +getAllOperations() Operation[]
    }

    class Ownable {
        +address owner()
        +transferOwnership(address)
        +onlyOwner modifier
    }

    class ReentrancyGuard {
        +nonReentrant modifier
    }

    class SafeERC20 {
        +safeTransfer()
        +safeTransferFrom()
    }

    Ownable <|-- Escrow
    ReentrancyGuard <|-- Escrow
    SafeERC20 <.. Escrow : uses
```
