# Variables de Entorno - Referencia Completa

Este documento describe todas las variables de entorno disponibles en el proyecto y cómo usarlas.

## 📦 Archivos de Configuración

### 1. `.env.example` (Template)
Archivo template que muestra todas las variables disponibles.

**Ubicación:** Raíz del proyecto
**NO modificar** - Este es solo un template de referencia.

### 2. `web/.env.local` (Auto-generado)
Archivo de configuración para Next.js, creado automáticamente por `setup.sh`.

**Ubicación:** `web/.env.local`

**Contiene:**
- Direcciones de contratos desplegados
- Cuentas de Anvil
- Private keys (para desarrollo local)

**NO commitear** - Ya está en `.gitignore`

### 3. Variables de Shell (Exportadas)
Variables exportadas por los scripts `setup.sh`, `start.sh` y `accounts.sh`.

**Uso:**
```bash
source ./accounts.sh
echo $ANVIL_ACCOUNT_0
```

## 🔑 Variables Disponibles

### Red de Anvil

```bash
RPC_URL=http://localhost:8545
CHAIN_ID=31337
```

### Cuenta #0 - Admin/Deployer

```bash
ANVIL_ACCOUNT_0=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
ANVIL_PRIVATE_KEY_0=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**Uso:** Desplegar contratos, funciones de administrador

### Cuenta #1 - User 1

```bash
ANVIL_ACCOUNT_1=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
ANVIL_PRIVATE_KEY_1=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

**Uso:** Usuario que crea operaciones de escrow

### Cuenta #2 - User 2

```bash
ANVIL_ACCOUNT_2=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
ANVIL_PRIVATE_KEY_2=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
```

**Uso:** Usuario que completa operaciones de otros

### Contratos (Auto-generados)

Estas variables se crean después de ejecutar `setup.sh`:

```bash
NEXT_PUBLIC_ESCROW_ADDRESS=0x...    # Dirección del contrato Escrow
NEXT_PUBLIC_TOKEN_A_ADDRESS=0x...   # Dirección del Token A (TKA)
NEXT_PUBLIC_TOKEN_B_ADDRESS=0x...   # Dirección del Token B (TKB)
```

## 📋 Uso en Diferentes Contextos

### En Scripts Bash

```bash
#!/bin/bash

# Opción 1: Source accounts.sh
source ./accounts.sh

# Usar variables
echo "Desplegando con cuenta: $ANVIL_ACCOUNT_0"
forge create src/MiContrato.sol:MiContrato \
  --rpc-url $RPC_URL \
  --private-key $ANVIL_PRIVATE_KEY_0
```

### En Next.js (web/)

Las variables con prefijo `NEXT_PUBLIC_` están disponibles en el cliente:

```typescript
// En cualquier componente o página
const escrowAddress = process.env.NEXT_PUBLIC_ESCROW_ADDRESS
const chainId = process.env.NEXT_PUBLIC_CHAIN_ID
const account0 = process.env.NEXT_PUBLIC_ANVIL_ACCOUNT_0
```

### En Cast

```bash
# Cargar variables
source ./accounts.sh

# Enviar transacción
cast send $ESCROW_ADDRESS \
  "addToken(address)" $TOKEN_ADDRESS \
  --rpc-url $RPC_URL \
  --private-key $ANVIL_PRIVATE_KEY_0
```

## 🔄 Flujo de Variables

```
setup.sh
  ├─→ Exporta a shell: ANVIL_ACCOUNT_*, ANVIL_PRIVATE_KEY_*
  ├─→ Crea: web/.env.local (para Next.js)
  └─→ Crea: deployment-info.txt (para referencia)

accounts.sh
  └─→ Exporta a shell cuando se hace "source"

start.sh
  └─→ Usa variables de setup.sh o las define
```

## 🛡️ Seguridad

### ⚠️ Reglas Importantes

1. **Nunca** commitear `.env` o `.env.local`
2. **Nunca** usar estas private keys en mainnet
3. **Nunca** compartir private keys en repositorios públicos
4. **Siempre** usar `.env.example` como template
5. **Siempre** regenerar claves para producción

### ✅ Buenas Prácticas

```bash
# ✅ BIEN - Variables en archivo .env local
echo "PRIVATE_KEY=0x..." > .env
source .env

# ✅ BIEN - Usar variables de entorno
const privateKey = process.env.PRIVATE_KEY

# ❌ MAL - Hardcodear en el código
const privateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
```

## 🆘 Troubleshooting

### Variable no está definida

```bash
# Solución:
source ./accounts.sh
```

### .env.local no se crea

```bash
# Ejecutar setup.sh primero
./setup.sh
```

### Variables no se actualizan en Next.js

```bash
# Reiniciar el servidor:
cd web && npm run dev
```
