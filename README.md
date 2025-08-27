# Pulse Streams — Starter Monorepo

This repository contains a **starter skeleton** for Pulse Streams.

## Structure
```
/contracts   — Foundry (Solidity ^0.8.20)
/scripts     — Node (ts-node) utilities
/docs        — Docs (addresses, notes)
```

> Frontend will be generated with `create-next-app` (instructions below).

## Quick start

### Prerequisites
- Node.js >= 18
- Git
- Foundry (Solidity toolchain)
  ```bash
  curl -L https://foundry.paradigm.xyz | bash
  foundryup
  ```

### Contracts
```bash
cd contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge build
forge test -vvv
```

### Scripts (CSV -> Merkle, deploy helpers)
```bash
cd ../scripts
npm i
npm run build
# Example:
# node dist/merkle.js --csv ./samples/airdrop.csv --out ./out
```

### Frontend (create later)
```bash
cd ..
mkdir web && cd web
npx create-next-app@latest . --ts --eslint --tailwind --app --src-dir --import-alias "@/*"
npm i framer-motion recharts lucide-react viem wagmi
```
