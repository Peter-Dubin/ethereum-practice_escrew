# Proyecto Escrow DApp - Guía para Estudiantes

## Objetivo del Proyecto

Crear una aplicación descentralizada (DApp) completa para realizar intercambios seguros de tokens ERC20 utilizando un contrato inteligente de escrow. El proyecto incluye:

- **Smart Contract**: Contrato Escrow en Solidity que gestiona operaciones de intercambio de tokens
- **Frontend Web**: Aplicación Next.js que permite interactuar con el contrato
- **Integración Web3**: Conexión con MetaMask usando ethers.js

## Funcionalidades Principales

1. **Agregar Tokens**: El owner puede autorizar qué tokens ERC20 se pueden intercambiar
2. **Crear Operación**: Usuario 1 deposita Token A y solicita Token B a cambio
3. **Completar Operación**: Usuario 2 proporciona Token B y recibe Token A
4. **Cancelar Operación**: Usuario 1 puede cancelar y recuperar sus tokens
5. **Visualizar Estado**: Panel de debug para ver balances y operaciones activas

## Arquitectura del Proyecto

```
90_escrow/
├── sc/                          # Smart Contracts (Foundry)
│   ├── src/
│   │   └── Escrow.sol          # Contrato principal
│   ├── script/
│   │   └── Deploy.s.sol        # Script de deployment
│   └── test/
│       └── Escrow.t.sol        # Tests del contrato
│
├── web/                         # Frontend (Next.js 14)
│   ├── app/
│   │   └── page.tsx            # Página principal
│   ├── components/
│   │   ├── ConnectButton.tsx   # Conectar wallet
│   │   ├── AddToken.tsx        # Agregar tokens permitidos
│   │   ├── CreateOperation.tsx # Crear operación de swap
│   │   ├── OperationsList.tsx  # Lista de operaciones
│   │   └── BalanceDebug.tsx    # Debug de balances
│   └── lib/
│       ├── ethereum.tsx        # Context provider de Ethereum
│       └── contracts.ts        # ABIs y direcciones
│
├── deploy.sh                    # Script de deployment automático
└── README_ESTUDIANTE.md        # Este archivo
```

## Pasos para Realizar el Proyecto con IA

### Fase 1: Setup Inicial

**Prompt sugerido:**
```
Necesito crear un proyecto DApp de escrow para intercambio de tokens ERC20.
Estructura:
- Smart contracts con Foundry
- Frontend con Next.js 14 y ethers.js
- Debe permitir crear operaciones de swap, completarlas y cancelarlas

Crea la estructura básica del proyecto con los directorios necesarios.
```

### Fase 2: Smart Contract

**Prompt sugerido:**
```
Crea el contrato Escrow.sol con estas funcionalidades:
- Heredar de Ownable y ReentrancyGuard de OpenZeppelin
- addToken(address): solo owner puede agregar tokens permitidos
- createOperation(tokenA, tokenB, amountA, amountB): crear operación de swap
  * Transferir tokenA del usuario al contrato
  * Guardar la operación como activa
- completeOperation(operationId): completar swap
  * Transferir tokenB del usuario2 al usuario1
  * Transferir tokenA del contrato al usuario2
  * Solo puede completarla alguien diferente al creador
- cancelOperation(operationId): cancelar operación
  * Devolver tokenA al creador
  * Solo el creador puede cancelar
- getAllowedTokens(): retornar lista de tokens permitidos
- getAllOperations(): retornar todas las operaciones

Incluye eventos para TokenAdded, OperationCreated, OperationCompleted, OperationCancelled
```

**Prompt de pruebas:**
```
Crea tests completos para el contrato Escrow.sol usando Foundry.
Prueba todos los casos: happy path, reverts, edge cases.
```

### Fase 3: Scripts de Deployment

**Prompt sugerido:**
```
Crea un script deploy.sh que:
1. Despliegue el contrato Escrow
2. Despliegue dos tokens ERC20 de prueba (TokenA y TokenB)
3. Agregue ambos tokens al contrato Escrow
4. Mint 1000 tokens de cada tipo a las cuentas de test de Anvil:
   - 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
   - 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
   - 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
5. Actualice automáticamente la dirección del contrato en web/lib/contracts.ts
6. Genere un archivo deployment-info.txt con las direcciones

El script debe asumir que Anvil ya está corriendo en http://localhost:8545
```

### Fase 4: Frontend - Setup Base

**Prompt sugerido:**
```
Crea el setup base del frontend:
1. Configurar Next.js 14 con TypeScript
2. Instalar ethers.js v6
3. Configurar Tailwind CSS v4
4. Crear el context provider de Ethereum en lib/ethereum.tsx que:
   - Gestione la conexión con MetaMask
   - Provea provider, signer, account
   - Auto-reconecte al refrescar la página
5. Crear lib/contracts.ts con los ABIs del contrato Escrow y ERC20
```

### Fase 5: Componente de Conexión

**Prompt sugerido:**
```
Crea el componente ConnectButton.tsx que:
- Muestre "Connect Wallet" si no está conectado
- Al hacer clic, conecte con MetaMask
- Si está conectado, muestre la dirección abreviada (0x1234...5678)
- Incluya un botón de disconnect
- Evite errores de hidratación con el hook de mounted
```

### Fase 6: Componente AddToken

**Prompt sugerido:**
```
Crea el componente AddToken.tsx que:
- Muestre un formulario para agregar la dirección de un token
- Al enviar, llame a addToken() del contrato
- Muestre la dirección del contrato Escrow
- Liste todos los tokens ya agregados con su símbolo y dirección
- Solo el owner puede usar esta función
```

### Fase 7: Componente CreateOperation

**Prompt sugerido:**
```
Crea el componente CreateOperation.tsx que:
- Tenga dropdowns para seleccionar Token A y Token B desde los tokens permitidos
- Campos numéricos para Amount A y Amount B
- Al enviar, ejecute en un solo paso:
  1. approve() de Token A al contrato Escrow
  2. createOperation() con los parámetros ingresados
- Muestre mensajes de éxito/error
- Refresque la página después de crear exitosamente
```

### Fase 8: Componente OperationsList

**Prompt sugerido:**
```
Crea el componente OperationsList.tsx que:
- Liste todas las operaciones usando getAllOperations()
- Para cada operación muestre:
  * ID, creador, tokens involucrados, cantidades
  * Estado: Active o Closed
- Si el usuario conectado es el creador y está activa:
  * Botón "Cancel Operation"
- Si el usuario conectado NO es el creador y está activa:
  * Botón "Complete Operation" que ejecute approve + completeOperation en un paso
- Auto-refresque cada 5 segundos
- Maneje el caso cuando no hay operaciones (array vacío)
```

### Fase 9: Componente BalanceDebug

**Prompt sugerido:**
```
Crea el componente BalanceDebug.tsx que:
- Muestre los balances de ETH y tokens para:
  1. El contrato Escrow (destacado en azul)
  2. Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  3. Account #1: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
  4. Account #2: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
- Incluya un botón "Refresh" para actualizar manualmente
- Maneje el caso cuando no hay tokens aún (array vacío)
```

### Fase 10: Página Principal

**Prompt sugerido:**
```
Crea la página principal app/page.tsx que:
- Muestre el header con título "Escrow DApp" y el ConnectButton
- Si no está conectado: mensaje de bienvenida
- Si está conectado: grid con 3 columnas:
  * Columna 1: AddToken y CreateOperation
  * Columna 2: OperationsList
  * Columna 3: BalanceDebug
- Footer con información del proyecto
```

### Fase 11: Manejo de Errores

**Prompt sugerido:**
```
Agrega manejo de errores robusto en todos los componentes:
- Si getAllowedTokens() falla (0 tokens), usar array vacío
- Si getAllOperations() falla (0 operaciones), usar array vacío
- Mostrar mensajes de error claros al usuario
- Manejar errores de MetaMask (usuario rechaza transacción, etc)
```

### Fase 12: Testing End-to-End

**Prompt sugerido:**
```
Documenta el flujo de prueba completo:
1. Iniciar Anvil
2. Ejecutar deploy.sh
3. Importar cuentas de test en MetaMask
4. Agregar tokens permitidos
5. Crear operación con cuenta 1
6. Cambiar a cuenta 2 en MetaMask
7. Completar operación con cuenta 2
8. Verificar balances actualizados
9. Probar cancelación de operación
```

## Flujo de Uso Típico

### 1. Setup del Entorno

```bash
# Terminal 1: Iniciar Anvil (blockchain local)
anvil

# Terminal 2: Desplegar contratos
cd /path/to/90_escrow
./deploy.sh

# Terminal 3: Iniciar frontend
cd web
npm install
npm run dev
```

### 2. Configurar MetaMask

- Agregar red local: http://localhost:8545, Chain ID: 31337
- Importar las 3 cuentas de test usando sus private keys (mostradas por Anvil)

### 3. Usar la DApp

**Como Owner (Cuenta 0):**
1. Conectar wallet
2. Agregar tokens permitidos (TokenA y TokenB ya están desplegados)
3. Ver que aparecen en la lista

**Como Usuario 1 (Cuenta 0):**
1. Crear operación: Ofrecer 100 TKA por 50 TKB
2. Aprobar y confirmar en MetaMask (2 transacciones)
3. Ver la operación en la lista como "Active"

**Como Usuario 2 (Cuenta 1 o 2):**
1. Cambiar de cuenta en MetaMask
2. Ver la operación creada por Usuario 1
3. Click en "Complete Operation"
4. Aprobar y confirmar en MetaMask (2 transacciones)
5. Ver que la operación cambia a "Closed"
6. Verificar en BalanceDebug que los tokens se intercambiaron

**Cancelación (Usuario 1):**
1. Si no se completó, Usuario 1 puede cancelar
2. Click en "Cancel Operation"
3. Los tokens regresan al creador

## Tecnologías Utilizadas

- **Solidity 0.8.13**: Lenguaje de smart contracts
- **Foundry**: Framework para desarrollo y testing de contratos
- **OpenZeppelin**: Librerías estándar (Ownable, ReentrancyGuard, IERC20)
- **Next.js 14**: Framework de React con App Router
- **TypeScript**: Tipado estático
- **Ethers.js v6**: Librería para interactuar con Ethereum
- **Tailwind CSS v4**: Estilos
- **MetaMask**: Wallet de navegador

## Conceptos Clave Aprendidos

### Smart Contracts
- Patrón Escrow para intercambios seguros
- Control de acceso con Ownable
- Protección contra reentrancy
- Gestión de tokens ERC20
- Eventos para tracking
- Modifiers personalizados

### Frontend Web3
- Conexión con wallet (MetaMask)
- Firma de transacciones
- Lectura de estado del contrato (view functions)
- Escritura en blockchain (transacciones)
- Manejo de aprobaciones ERC20
- Auto-refresh de datos

### Flujo de Trabajo
- Deployment automatizado
- Testing de contratos
- Gestión de direcciones de contratos
- Debugging con balance tracking
- Manejo de múltiples cuentas

## Troubleshooting Común

### Error: "could not decode result data"
**Causa**: Intentar llamar `getAllowedTokens()` o `getAllOperations()` cuando el array está vacío.
**Solución**: Agregar try-catch y usar array vacío como fallback.

### Error: "Cannot complete your own operation"
**Causa**: Intentar completar una operación que tu mismo creaste.
**Solución**: Cambiar de cuenta en MetaMask antes de completar.

### Error: "Insufficient allowance"
**Causa**: No se aprobó el token antes de crear/completar la operación.
**Solución**: Los componentes ya manejan approve automáticamente.

### Error: "Operation is not active"
**Causa**: Intentar completar/cancelar una operación ya cerrada.
**Solución**: Refrescar la lista de operaciones.

### MetaMask no se conecta
**Causa**: Red incorrecta o cuentas no importadas.
**Solución**: Verificar que MetaMask está en localhost:8545 con Chain ID 31337.

## Siguientes Pasos / Mejoras Posibles

1. **Agregar fees**: Cobrar una comisión por cada swap
2. **Expiración temporal**: Operaciones que expiren después de X tiempo
3. **Ofertas parciales**: Permitir completar solo parte de una operación
4. **Sistema de reputación**: Rating de usuarios
5. **Notificaciones**: Alertas cuando se completa una operación
6. **Filtros y búsqueda**: Buscar operaciones por token
7. **Historial**: Ver operaciones completadas/canceladas
8. **Multi-chain**: Desplegar en múltiples redes
9. **Tests E2E**: Usar Playwright o Cypress
10. **Subgraph**: Indexar eventos con The Graph

## Recursos Adicionales

- **Foundry Book**: https://book.getfoundry.sh/
- **Ethers.js Docs**: https://docs.ethers.org/v6/
- **OpenZeppelin**: https://docs.openzeppelin.com/
- **Next.js**: https://nextjs.org/docs
- **Solidity by Example**: https://solidity-by-example.org/

## Licencia

MIT
