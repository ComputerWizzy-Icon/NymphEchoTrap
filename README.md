
# NymphEchoTrap

**Status:** Drosera-compatible stateless trap
**Author:** Sekani chief JayCool BFF
**Version:** 1.0

---

## Overview

`NymphEchoTrap` is a **stateless Drosera trap** designed to detect anomalies in smart contract deployments, balances, and block number sequences. The trap adheres strictly to the Drosera protocol, exposing only the required interfaces `collect()` and `shouldRespond()` for relay-driven detection.

This trap does **not** store mutable state or call responders directly, ensuring deterministic execution across all Drosera operators. It is fully compatible with private traps and Drosera relays.

---

## Features

* Stateless and deterministic, fully compatible with Drosera.
* Detects three types of anomalies:

  1. **Code changes** (`codehash` mismatch)
  2. **Balance changes** (ETH balance deviation)
  3. **Block anomalies** (new sample block ≤ previous sample block)
* Generates payload data for responders without directly invoking them.
* Handles empty or missing data safely to prevent reverts.

---

## Contract Architecture

### 1. NymphEchoTrap.sol

Implements `ITrap` interface:

```solidity
function collect() external view returns (bytes)
function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory)
```

**`collect()`**

* Captures a snapshot of the trap contract:

  * Contract address (`target`)
  * Caller (`watch`)
  * Contract `codehash`
  * Contract balance
  * Current block number

**`shouldRespond()`**

* Stateless comparison of the last two samples: newest vs previous.
* Returns:

  * `bool` → true if any anomaly detected
  * `bytes` → encoded payload for the responder

**Helper functions:**

* `_decodeSafe()` → safely decodes raw `bytes` into a `Sample` struct
* `_reason()` → returns a human-readable string explaining the anomaly

---

### 2. NymphEchoResponder.sol

A lightweight contract that emits an event when anomalies are detected.

```solidity
event EchoIncident(
    address indexed target,
    address indexed watchAddr,
    bytes32 oldCodehash,
    bytes32 newCodehash,
    uint256 oldBalance,
    uint256 newBalance,
    uint256 oldBlock,
    uint256 newBlock
);

function respondWithEchoAlert(
    address _target,
    address _watchAddr,
    bytes32 _oldCodeh,
    bytes32 _newCodeh,
    uint256 _oldBal,
    uint256 _newBal,
    uint256 _oldBlock,
    uint256 _newBlock
) external;
```

* Designed to be called **only by the Drosera relay** after `shouldRespond()` returns `true`.
* Does **not** perform any imperative logic; strictly emits events.

---

## Deployment Instructions

1. Set up `.env` with your keys:

```env
ETH_RPC_URL=<your-eth-rpc>
DROSERA_RPC_URL=<your-drosera-relay>
PRIVATE_KEY=<your-private-key>

RESPONSE_CONTRACT=<deployed responder address>
```

2. Compile and deploy using Foundry:

```bash
forge script script/DeployAll.s.sol:DeployAll --rpc-url $ETH_RPC_URL --broadcast
```

3. Copy the deployed addresses into `.env` and Drosera TOML config.

---

## Drosera TOML Example

```toml
[traps.nymph_echo]
path = "out/NymphEchoTrap.sol/NymphEchoTrap.json"
response_contract = "0xa1fB3f289d392BF720A9D2798ECFB750837C7b2b"
response_function = "respondWithEchoAlert(address,address,bytes32,bytes32,uint256,uint256,uint256,uint256,string)"
cooldown_period_blocks = 20
min_number_of_operators = 1
max_number_of_operators = 3
block_sample_size = 2
private_trap = true
whitelist = ["0x14e424df0c35686cf58fc7d05860689041d300f6"]
```

* `block_sample_size = 2` → only compares newest vs previous sample.
* `private_trap = true` → restricts usage to your private whitelist.
* `whitelist` → replace with Drosera operator addresses allowed to run the trap.

---

## Notes

* **No constructor parameters**: ensures deterministic deployment.
* **No on-chain storage**: state is derived from `bytes[] data` provided by Drosera relay.
* **No direct calls to responder**: Drosera relay handles invocation after `shouldRespond()`.

---

## License

MIT

---