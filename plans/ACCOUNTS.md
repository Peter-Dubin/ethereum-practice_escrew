# Cuentas de Anvil - Guía Rápida

## 🔑 Acceso Rápido a las Cuentas

### Mostrar Todas las Cuentas

```bash
./accounts.sh
```

### Cargar Variables de Entorno

```bash
source ./accounts.sh
```

Después puedes usar las variables:
```bash
echo $ANVIL_ACCOUNT_0
echo $ANVIL_PRIVATE_KEY_0
```

## 📋 Cuentas Disponibles

### Account #0 - Admin/Deployer

```bash
Address:     0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

**Uso:** Cuenta para desplegar contratos y actuar como administrador.

### Account #1 - User 1

```bash
Address:     0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Private Key: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

**Uso:** Usuario que crea operaciones de escrow.

### Account #2 - User 2

```bash
Address:     0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
Private Key: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
```

**Uso:** Usuario que completa operaciones de otros.

## 🌐 Variables de Entorno

Después de ejecutar `./setup.sh`, estas variables están disponibles:

| Variable | Descripción |
|----------|-------------|
| `ANVIL_ACCOUNT_0` | Dirección de la cuenta #0 |
| `ANVIL_PRIVATE_KEY_0` | Clave privada de la cuenta #0 |
| `ANVIL_ACCOUNT_1` | Dirección de la cuenta #1 |
| `ANVIL_PRIVATE_KEY_1` | Clave privada de la cuenta #1 |
| `ANVIL_ACCOUNT_2` | Dirección de la cuenta #2 |
| `ANVIL_PRIVATE_KEY_2` | Clave privada de la cuenta #2 |
| `RPC_URL` | URL del RPC de Anvil |
| `PRIVATE_KEY` | Clave privada por defecto (cuenta #0) |

## 📁 Archivo .env.local

Después de ejecutar `./setup.sh`, se crea automáticamente `web/.env.local`:

```bash
# Anvil Local Network
NEXT_PUBLIC_CHAIN_ID=31337
NEXT_PUBLIC_RPC_URL=http://localhost:8545

# Contract Addresses
NEXT_PUBLIC_ESCROW_ADDRESS=0x...
NEXT_PUBLIC_TOKEN_A_ADDRESS=0x...
NEXT_PUBLIC_TOKEN_B_ADDRESS=0x...

# Anvil Test Accounts
NEXT_PUBLIC_ANVIL_ACCOUNT_0=0xf39...
NEXT_PUBLIC_ANVIL_ACCOUNT_1=0x709...
NEXT_PUBLIC_ANVIL_ACCOUNT_2=0x3C4...

# Private Keys
ANVIL_PRIVATE_KEY_0=0xac0...
ANVIL_PRIVATE_KEY_1=0x59c...
ANVIL_PRIVATE_KEY_2=0x5de...
```

## 🔧 Uso en Scripts

### Ejemplo 1: Desplegar un Contrato

```bash
# Cargar variables
source ./accounts.sh

# Usar cuenta #0 (admin)
cd sc
forge create src/MiContrato.sol:MiContrato \
  --rpc-url $RPC_URL \
  --private-key $ANVIL_PRIVATE_KEY_0
```

### Ejemplo 2: Enviar una Transacción con Cuenta #1

```bash
# Cargar variables
source ./accounts.sh

# Usar cuenta #1
cast send 0xContractAddress \
  "miFunction(uint256)" 100 \
  --rpc-url $RPC_URL \
  --private-key $ANVIL_PRIVATE_KEY_1
```

### Ejemplo 3: Consultar Balance

```bash
# Cargar variables
source ./accounts.sh

# Ver balance de cuenta #2
cast balance $ANVIL_ACCOUNT_2 --rpc-url $RPC_URL
```

## 🦊 Configuración de MetaMask

### 1. Agregar Red Localhost

- **Network Name:** Localhost 8545
- **RPC URL:** `http://localhost:8545`
- **Chain ID:** `31337`
- **Currency Symbol:** ETH

### 2. Importar Cuenta

1. Click en el icono de cuenta (arriba derecha)
2. "Import Account"
3. Pega una de las private keys de arriba
4. Click "Import"

### 3. Ver Tokens

Los tokens TKA y TKB no aparecen automáticamente. Para verlos:

1. Ve a "Assets" → "Import tokens"
2. Pega la dirección del token (de `deployment-info.txt`)
3. El símbolo se detectará automáticamente

## 📝 Notas Importantes

### ⚠️ Seguridad

- **NUNCA uses estas claves en mainnet o con fondos reales**
- Son claves públicas de Anvil, conocidas por todos
- Solo para desarrollo local
- Para producción: usa hardware wallet o claves únicas

### Balance Inicial

Cada cuenta tiene:
- **10,000 ETH** (para gas)
- **1,000 TKA** (Token A)
- **1,000 TKB** (Token B)

### Reiniciar Anvil

Cuando reinicias Anvil, los balances se resetean:

```bash
./stop.sh
./start.sh
```

Esto redesplegará los contratos y reasignará tokens.

## 🔍 Verificar Estado

### Ver todas las cuentas con balances

```bash
cast rpc eth_accounts --rpc-url http://localhost:8545
```

### Ver balance de ETH

```bash
cast balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545
```

### Ver balance de Token

```bash
cast call $TOKEN_ADDRESS \
  "balanceOf(address)(uint256)" \
  $ANVIL_ACCOUNT_0 \
  --rpc-url $RPC_URL
```

## 🆘 Troubleshooting

### "Insufficient funds for gas"

**Solución:** Resetea Anvil
```bash
./stop.sh
./start.sh
```

### "Nonce too low" en MetaMask

**Solución:** Resetea la cuenta en MetaMask
- Settings → Advanced → Clear activity tab data

### "Transaction failed" sin razón aparente

**Solución:** Verifica que:
1. Anvil está corriendo: `curl -X POST http://localhost:8545 -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'`
2. Estás en la red correcta (localhost:8545)
3. La cuenta tiene suficiente ETH

## 📚 Archivos Relacionados

- `accounts.sh` - Script para mostrar/cargar cuentas
- `.env.example` - Template de variables de entorno
- `web/.env.local` - Variables para Next.js (auto-generado)
- `deployment-info.txt` - Info completa del deployment (auto-generado)
- `setup.sh` - Script que configura todo
- `start.sh` - Script de inicio completo

## 💡 Tips

1. **Usa diferentes cuentas para testing:**
   - Account #0 para admin
   - Account #1 para crear operaciones
   - Account #2 para completar operaciones

2. **Source accounts.sh en tu shell:**
   ```bash
   echo "source ~/path/to/accounts.sh" >> ~/.zshrc
   ```

3. **Alias útiles:**
   ```bash
   alias anvil-accounts='cd /path/to/project && ./accounts.sh'
   alias anvil-reset='./stop.sh && ./start.sh'
   ```

4. **Ver información rápida:**
   ```bash
   cat deployment-info.txt
   ```
