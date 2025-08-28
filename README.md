# MerkleAirdrop

A gas-efficient token airdrop contract using Merkle trees and EIP-712 signatures.

## What it does
- Users sign a message to authorize their claim
- Anyone can pay gas to submit the claim transaction
- Merkle proofs ensure only whitelisted addresses can claim
- Each address can only claim once

## Quick Start
```bash
# Install dependencies
forge install

# Run tests
forge test

# Deploy
forge script script/DeployMerkleAirdrop.s.sol --broadcast
```

## Contracts
- `MerkleAirdrop.sol` - Main airdrop contract
- `SimpleToken.sol` - ERC20 token for testing