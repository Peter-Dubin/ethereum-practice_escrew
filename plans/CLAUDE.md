# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a monorepo containing an escrow application with two main components:
- `sc/`: Smart contracts built with Foundry (Solidity)
- `web/`: Frontend application built with Next.js 16 and React 19

## Quick Setup Scripts

**Recommended Simple Setup:**
```bash
anvil                    # Terminal 1 - keep running
./setup-simple.sh        # Terminal 2 - deploy contracts
./verify-setup.sh        # Verify everything is configured
cd web && npm run dev    # Start web app
```

Other available scripts:

**Full setup and start:**
```bash
./start.sh
```
This checks/starts Anvil, deploys contracts, configures the web app, and starts the dev server.

**Deploy contracts only:**
```bash
./setup.sh
```
This deploys Escrow + 2 mock ERC20 tokens, adds them to the escrow, mints test tokens, and updates web config.

**Verify setup:**
```bash
./verify-setup.sh
```
Checks that Anvil is running, contracts are deployed, and configuration is correct.

**Stop all services:**
```bash
./stop.sh
```
This stops both Anvil and the Next.js dev server.

After running `setup.sh` or `setup-simple.sh`, contract addresses and account details are saved in `deployment-info.txt`.

**Important:** See SETUP-GUIDE.md for complete MetaMask configuration instructions.

## Development Commands

### Smart Contracts (sc/)

All Foundry commands should be run from the `sc/` directory.

**Build contracts:**
```bash
cd sc && forge build
```

**Run tests:**
```bash
cd sc && forge test
```

**Run specific test:**
```bash
cd sc && forge test --match-test test_Increment
```

**Format code:**
```bash
cd sc && forge fmt
```

**Generate gas snapshots:**
```bash
cd sc && forge snapshot
```

**Deploy contracts:**
```bash
cd sc && forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

**Run local node:**
```bash
anvil
```

### Web Frontend (web/)

All npm commands should be run from the `web/` directory.

**Install dependencies:**
```bash
cd web && npm install
```

**Run development server:**
```bash
cd web && npm run dev
```
The app will be available at http://localhost:3000

**Build for production:**
```bash
cd web && npm run build
```

**Start production server:**
```bash
cd web && npm run start
```

**Lint code:**
```bash
cd web && npm run lint
```

## Architecture

### Smart Contracts (sc/)

- **Structure**: Standard Foundry project layout
  - `src/`: Contract source files
  - `test/`: Test files (using Forge's testing framework)
  - `script/`: Deployment scripts
  - `lib/`: Dependencies (forge-std is included)
- **Testing**: Uses Forge's testing framework with support for unit tests and fuzz tests
- **Configuration**: `foundry.toml` contains project settings

### Web Frontend (web/)

- **Framework**: Next.js 16 with App Router architecture
- **React Version**: 19.2.0 (latest)
- **Styling**: Tailwind CSS v4 with PostCSS
- **TypeScript**: Strict mode enabled
- **Structure**:
  - `app/`: Next.js App Router pages and layouts
    - `layout.tsx`: Root layout with Geist fonts
    - `page.tsx`: Home page component
    - `globals.css`: Global styles and Tailwind directives
  - Path aliases: `@/*` maps to root directory

### Monorepo Structure

## FUNCIONES DEL CONTRATO

Se trata de hacer un contrato scrow que maneje n tokens ERC20. 

El usuario1 deposita amountA tokens A en el contrato a cambio de amountB tokens B en una operacion1.

Si un usuario2 deposita en la operacion1 amountB tokens  B, el contrato le entrega amountA tokens A al usuario2 y enviara amountB tokens B al usuario1.

El contrato debe de permitir que el usuario1 retire amountA tokens A en el contrato.

El contrato le debe de permitir al administrator add new tokens to the contrato.

FUNCIONES DE LA WEB.

Al administrador le debe de permitir add tokens to the contrato.

Al usuario:
- iniciar una operacion en la que debe indicar el token A, el token B y la cantidad de tokens A que aporta y los que desea de token B.
- ver las operaciones.
- dada una operacion que este abierta el usuario depositar tokens B.
- cuando el usuario deposita tokens B, el contrato debe de enviarle tokens A al usuario y token B al usuario1 y la operacion debe de cerrarse y ponerle la fecha.

