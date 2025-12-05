# NymphEchoTrap

A trust-minimized monitoring trap for Drosera smart contracts, enabling anomaly detection and automated alerts through a responder contract. Designed to work with a whitelist of allowed operators.

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Folder Structure](#folder-structure)
4. [Installation](#installation)
5. [Environment Variables](#environment-variables)
6. [Deployment](#deployment)
7. [Usage](#usage)
8. [Testing](#testing)
9. [Security Considerations](#security-considerations)
10. [License](#license)

---

## Overview

`NymphEchoTrap` is a Solidity project built with Foundry that monitors a target contract for:

* Code hash changes
* Balance changes
* Block inconsistencies

When an anomaly is detected, it triggers the `NymphEchoResponder` contract to log or alert the relevant parties. Only whitelisted operators can execute the checks.

---

## Features

* Modular design with `WhitelistOperator` for access control
* Anomaly detection via `check()` function
* Automated alerting using `NymphEchoResponder`
* Configurable target and watch addresses
* Fully tested with Foundry

---

## Folder Structure

```
nymph-echo-trap/
├── src/contracts/
│   ├── NymphEchoTrap.sol       # Main trap contract
│   ├── NymphEchoResponder.sol  # Handles alerts/responses
│   ├── WhitelistOperator.sol   # Access control
│   └── Trap.sol                # Optional helper trap
├── test/
│   └── NymphEchoTrap.t.sol     # Test cases for trap contract
├── script/
│   └── DeployTrap.s.sol        # Deployment script
├── .env                        # Environment variables (PRIVATE_KEY, ETH_RPC_URL)
├── foundry.toml                # Foundry configuration
└── README.md                   # This file
```

---

## Installation

1. Install [Foundry](https://book.getfoundry.sh/getting-started/installation):

   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. Clone this repository:

   ```bash
   git clone https://github.com/<your-username>/nymph-echo-trap.git
   cd nymph-echo-trap
   ```

3. Install dependencies:

   ```bash
   forge install
   ```

---

## Environment Variables

Create a `.env` file in the root folder:

```env
PRIVATE_KEY=<your-wallet-private-key>
ETH_RPC_URL=<your-ethereum-node-url>
```

**Important:** Never commit `.env` to GitHub. Add it to `.gitignore`.

---

## Deployment

Deploy contracts using Foundry scripts:

```bash
source .env
forge script script/DeployTrap.s.sol --rpc-url $ETH_RPC_URL --broadcast --private-key $PRIVATE_KEY
```

Logs will show deployed addresses:

```
Whitelist deployed at: 0x...
Responder deployed at: 0x...
Trap deployed at: 0x...
```

---

## Usage

1. Add allowed operators via `WhitelistOperator`:

   ```solidity
   whitelist.setOperator(operatorAddress, true);
   ```

2. Run anomaly checks using whitelisted accounts:

   ```solidity
   trap.check(oldCodehash, newCodehash, oldBalance, newBalance, lastCheckedBlock);
   ```

3. The `NymphEchoResponder` will handle the response or alert.

---

## Testing

Run tests with Foundry:

```bash
forge test
```

Example output:

```
Ran 1 test suite: 1 tests passed; 0 failed
```

---

## Security Considerations

* **Private Key Management:** Never store private keys in GitHub or in scripts. Use `.env`.
* **RPC URLs:** Use secure endpoints and avoid exposing them publicly.
* **Whitelist:** Only trusted operators should be whitelisted to avoid unauthorized checks.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---
