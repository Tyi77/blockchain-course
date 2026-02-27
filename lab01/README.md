# Lab01 — EthVault

A secure Ethereum smart contract that acts as a vault: it accepts ETH deposits, emits events for all activity, and restricts withdrawals to a single authorized owner.

---

## Project Description

`EthVault` is a Solidity smart contract built for learning purposes as part of the BDaF 2026 course. It demonstrates:

- Accepting ETH via `receive()` with event emission
- Owner-only withdrawal with balance protection
- Unauthorized access handling via events (no silent failures)
- Full automated test coverage using Hardhat's Solidity test runner (Foundry-compatible)

---

## Project Structure

```
lab01/
├── contracts/
│   ├── EthVault.sol       # Main contract
├── test/
│   ├── EthVault.t.sol     # Solidity test file (Foundry-style)
├── hardhat.config.ts      # Hardhat configuration
├── package.json
└── README.md
```

---

## Solidity Version

```
pragma solidity ^0.8.0;
```

Compiled with `solc 0.8.28` (evm target: cancun).

---

## Framework

**Hardhat 3** (with Foundry-compatible Solidity test support via `hardhat-foundry`)

---

## Setup Instructions

### 1. Install dependencies

```bash
npm install
```
---

## Test Instructions
All 8 tests are located in `test/EthVault.t.sol`.

Run all tests:

```bash
npx hardhat test
```

All 8 tests should pass. Expected output:

```
8 passing (8 solidity)
```

### Test Coverage

| Group | Tests | What is Verified |
|-------|-------|-----------------|
| **Group A** | `test_SingleDeposit`, `test_MultipleDeposits`, `test_DifferentSenders` | ETH reception, `Deposit` event, balance increase |
| **Group B** | `test_OwnerWithdraw` | Partial & full owner withdrawal, `Weethdraw` event |
| **Group C** | `test_UnauthorizedWithdraw` | Non-owner blocked, `UnauthorizedWithdrawAttempt` event emitted, balance unchanged |
| **Group D** | `test_WithdrawMoreThanBalance`, `test_WithdrawZero`, `test_MultipleDepositsAndWithdraw` | Overdraw reverts, zero withdrawal handled, combined flow |
