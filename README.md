# NymphEchoTrap

**NymphEchoTrap** is a Solidity-based monitoring and alert system designed specifically for the **Drosera Network**. It tracks anomalies in Drosera smart contracts, including code changes, balance fluctuations, and block inconsistencies, and triggers alerts via the `NymphEchoResponder`. Access is controlled through the `WhitelistOperator` for secure monitoring.

This project is part of the Drosera ecosystem, helping maintain the integrity and security of Drosera nodes, traps, and contract interactions.

---

## Features

- Monitors Drosera contracts for:
  - Code changes (`codehash` differences)
  - Balance changes
  - Block inconsistencies
- Sends real-time alerts using `NymphEchoResponder`
- Controlled access via `WhitelistOperator`
- Compatible with Ethereum and EVM-based networks supporting Drosera
- Fully modular, upgradeable, and ready for integration with Drosera tools

---

## Repository Structure

```

.
├── src/contracts/              # Solidity contracts for Drosera monitoring
│   ├── NymphEchoTrap.sol       # Main trap contract
│   ├── NymphEchoResponder.sol  # Handles alert notifications
│   ├── Trap.sol
│   └── WhitelistOperator.sol
├── test/                       # Forge tests
│   └── NymphEchoTrap.t.sol
├── script/                     # Deployment scripts
│   └── DeployTrap.s.sol
├── lib/                        # Submodules for Drosera dependencies
│   ├── drosera-contracts/      # Drosera core contracts as submodule
│   ├── forge-std/
│   └── openzeppelin-contracts/
├── broadcast/                  # Deployment broadcast logs
├── .env                        # Environment variables (not committed)
├── foundry.toml                # Foundry project config
└── README.md

````

---

## Security Notes

- Never commit your private keys or RPC URLs to GitHub.
- `.env` is ignored by `.gitignore` to prevent leaks.
- Use a separate wallet with minimal funds for Drosera test deployments.
- Submodules like `drosera-contracts` are tracked separately for security and modularity.

---

## Setup

1. Clone the repo recursively (to include Drosera submodules):
```bash
git clone --recursive https://github.com/ComputerWizzy-Icon/NymphEchoTrap.git
cd NymphEchoTrap
````

2. Install Foundry if not already installed:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

3. Install dependencies:

```bash
forge install
```

4. Create a `.env` file with your private environment variables:

```
PRIVATE_KEY=<your-wallet-private-key>
ETH_RPC_URL=<your-ethereum-node-url>
```

---

## Deployment

Deploy NymphEchoTrap to monitor Drosera contracts:

### Simulated Deployment

```bash
forge script script/DeployTrap.s.sol
```

### On-chain Deployment

```bash
forge script script/DeployTrap.s.sol --rpc-url $ETH_RPC_URL --broadcast --private-key $PRIVATE_KEY
```

After deployment, logs will show the addresses for:

* `WhitelistOperator`
* `NymphEchoResponder`
* `NymphEchoTrap`

These contracts form the core Drosera monitoring system.

---

## Usage

1. Whitelist operators using `WhitelistOperator`.
2. Monitor a Drosera contract by calling:

```solidity
trap.check(oldCodehash, newCodehash, oldBal, newBal, lastCheckedBlock);
```

3. Alerts are automatically handled by `NymphEchoResponder`.

---

## Testing

Run Forge tests to ensure Drosera monitoring works:

```bash
forge test
```

---

## Submodules

`drosera-contracts` is included as a submodule for Drosera core functionality:

```bash
git submodule update --init --recursive
```

---

## Contributing

* Open issues or PRs for bugs or enhancements.
* Do not commit private keys, RPC URLs, or sensitive data.

---

## License

MIT License

```