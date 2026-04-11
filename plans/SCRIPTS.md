# Scripts de Automatización

Este proyecto incluye 3 scripts bash para facilitar el desarrollo y testing.

## 📋 Resumen de Scripts

| Script | Propósito | Uso |
|--------|-----------|-----|
| `start.sh` | Inicio completo del proyecto | `./start.sh` |
| `setup.sh` | Solo deployment de contratos | `./setup.sh` |
| `stop.sh` | Detener todos los servicios | `./stop.sh` |

---

## 🚀 start.sh - Inicio Completo

**Uso:** `./start.sh`

### ¿Qué hace?

1. **Verifica Anvil** - Comprueba si está corriendo
   - Si no está corriendo → lo inicia automáticamente
   - Si ya está corriendo → continúa con el deployment
   
2. **Deployment** 
   - Si no hay deployment previo → ejecuta `setup.sh`
   - Si ya existe deployment → pregunta si quiere redesplegar

3. **Dependencias Web**
   - Verifica si node_modules existe
   - Instala dependencias si es necesario

4. **Inicia Web Server**
   - Lanza `npm run dev` en el directorio web
   - Abre localhost:3000

### Salida

```
================================
  Escrow DApp is Ready! 🚀
================================

Services Running:
  ✓ Anvil (localhost:8545)
  ✓ Web App (localhost:3000)

Quick Access:
  Web App:     http://localhost:3000
  Anvil RPC:   http://localhost:8545
```

### Detener

Presiona `Ctrl+C` o ejecuta `./stop.sh`

---

## 🔧 setup.sh - Deployment de Contratos

**Uso:** `./setup.sh`

### ¿Qué hace?

1. **Verifica Anvil**
   ```bash
   Checking if Anvil is running...
   ✓ Anvil is running
   ```
   Si no está corriendo, muestra instrucciones y sale.

2. **Deploy Escrow Contract**
   ```bash
   Step 1: Deploying Escrow contract...
   ✓ Escrow deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3
   ```

3. **Deploy MockERC20 Tokens**
   ```bash
   Step 2: Deploying MockERC20 Token A...
   ✓ Token A deployed at: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
   
   Step 3: Deploying MockERC20 Token B...
   ✓ Token B deployed at: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
   ```

4. **Configura Escrow**
   ```bash
   Step 4: Adding Token A to Escrow contract...
   ✓ Token A added to Escrow
   
   Step 5: Adding Token B to Escrow contract...
   ✓ Token B added to Escrow
   ```

5. **Mintea Tokens de Prueba**
   ```bash
   Step 6: Minting tokens to test accounts...
   ✓ Tokens minted to Anvil accounts 0, 1, 2
   ```
   Cada cuenta recibe 1000 TKA y 1000 TKB.

6. **Actualiza Web Config**
   ```bash
   Step 7: Updating web configuration...
   ✓ Web configuration updated
   ```
   Actualiza `web/lib/contracts.ts` con la dirección del contrato.

7. **Guarda Información**
   ```bash
   Saving deployment information...
   ✓ Deployment info saved to deployment-info.txt
   ```

### Archivos Generados

- `deployment-info.txt` - Direcciones de contratos y cuentas
- `web/lib/contracts.ts` - Actualizado con nueva dirección de Escrow
- `web/lib/contracts.ts.backup` - Backup del archivo original

### Cuentas Configuradas

| Cuenta | Balance |
|--------|---------|
| 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 | 1000 TKA + 1000 TKB |
| 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 | 1000 TKA + 1000 TKB |
| 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC | 1000 TKA + 1000 TKB |

---

## 🛑 stop.sh - Detener Servicios

**Uso:** `./stop.sh`

### ¿Qué hace?

1. **Detiene Next.js (puerto 3000)**
   ```bash
   Stopping web server (port 3000)...
   ✓ Web server stopped
   ```

2. **Detiene Anvil (puerto 8545)**
   ```bash
   Stopping Anvil (port 8545)...
   ✓ Anvil stopped
   ```

### Notas

- Usa `kill` primero, luego `kill -9` si es necesario
- Limpia todos los procesos en los puertos 3000 y 8545
- Seguro de ejecutar múltiples veces

---

## 🎯 Casos de Uso

### Caso 1: Primera vez usando el proyecto

```bash
./start.sh
```

Esto hará todo: deployment + iniciar servicios.

### Caso 2: Ya tengo Anvil corriendo, solo quiero redesplegar

```bash
./setup.sh
```

### Caso 3: Quiero limpiar todo y empezar de nuevo

```bash
./stop.sh
rm deployment-info.txt
./start.sh
```

### Caso 4: Acabé de trabajar y quiero cerrar todo

```bash
./stop.sh
```

---

## ⚙️ Variables de Configuración

### En setup.sh

```bash
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
RPC_URL="http://localhost:8545"
```

- Usa la cuenta #0 de Anvil por defecto
- Conecta a localhost:8545

### Personalización

Si quieres usar una red diferente, edita estas variables en `setup.sh`:

```bash
# Para Sepolia testnet:
PRIVATE_KEY="TU_CLAVE_PRIVADA"
RPC_URL="https://sepolia.infura.io/v3/TU_API_KEY"
```

---

## 🐛 Troubleshooting

### Error: "Anvil is not running"

**Solución:**
```bash
# Terminal 1
anvil

# Terminal 2
./setup.sh
```

### Error: "Port already in use"

**Solución:**
```bash
./stop.sh
./start.sh
```

### Error: "Failed to deploy contract"

**Posibles causas:**
- Anvil no está corriendo → inicia Anvil
- Contratos no compilan → `cd sc && forge build`
- Problema de permisos → `chmod +x *.sh`

### Error: "npm: command not found"

**Solución:**
```bash
# Instala Node.js primero
brew install node  # en macOS
```

---

## 📝 Logs

### Ver logs de Anvil

Si `start.sh` inició Anvil:
```bash
tail -f anvil.log
```

### Ver deployment info

```bash
cat deployment-info.txt
```

---

## 🔐 Seguridad

⚠️ **IMPORTANTE:** Las claves privadas mostradas en estos scripts son las claves por defecto de Anvil.

**NUNCA uses estas claves en mainnet o con fondos reales.**

Para producción:
- Usa `.env` files
- No commitees claves privadas
- Usa hardware wallets o servicios seguros

---

## 🆘 Ayuda Rápida

```bash
# Ver todas las opciones
./setup.sh --help    # (no implementado aún)

# Ver versión de herramientas
forge --version
node --version
npm --version

# Verificar que Anvil está corriendo
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545
```
