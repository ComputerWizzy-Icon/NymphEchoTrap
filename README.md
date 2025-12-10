# **NymphEchoTrap**

**Status:** Drosera-compatible stateless trap
**Author:** Sekani chief JayCool BFF
**Version:** 1.1 (Bjorn-reviewed)

---

## **Overview**

`NymphEchoTrap` is a **stateless, deterministic Drosera trap** designed to detect critical anomalies in Ethereum contracts. It monitors:

* **Code changes** (`codehash`)
* **Balance shifts** (ETH balance deviations)
* **Block regressions** (new sample block < previous block)

The trap ensures **planner-safe execution**, **ABI alignment**, and **private trap compatibility**. It separates **collection**, **detection**, and **response** responsibilities, relying on the Drosera relay for secure, consistent invocation.

---

## **Key Improvements (Bjorn Review)**

1. **ABI Alignment**

   * Removed 9th argument (`reason string`) from trap payload to match responder’s 8-argument signature.
   * Ensures no decode mismatches or reverts during Drosera relay execution.

2. **Deterministic collect()**

   * Removed `msg.sender` and `address(this)` from the snapshot.
   * `TARGET` and `WATCH` are constants, producing consistent samples across operators.

3. **Block Progression Check**

   * Changed `<=` to `<` to detect **true block regressions** only.

4. **Planner-Safety Guard**

   * Skips execution if there are fewer than 2 samples or if samples are empty.

5. **Cleaner Payload Encoding**

   * Encodes exactly 8 fields (target, watch, oldCode, newCode, oldBalance, newBalance, oldBlock, newBlock).

---

## **Features**

* Stateless, no on-chain storage.
* Deterministic execution across all Drosera operators.
* Private trap support with operator whitelist.
* Generates precise payloads for responders, avoiding false positives.
* Safe handling of empty or missing data.

---

## **Contract Architecture**

### **1. NymphEchoTrap.sol**

Implements `ITrap` interface:

```solidity
function collect() external view returns (bytes)
function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory)
```

**collect()**

* Takes a snapshot of `TARGET` and `WATCH`:

```solidity
bytes32 codeh;
assembly { codeh := extcodehash(TARGET) }
return abi.encode(codeh, WATCH.balance, block.number);
```

* Fully deterministic: no `msg.sender` or `address(this)`.

**shouldRespond()**

* Compares newest vs previous sample: code, balance, block.
* Returns `(true, payload)` if anomaly detected:

```solidity
bytes memory payload = abi.encode(
    TARGET,
    WATCH,
    prevCodehash,
    curCodehash,
    prevBalance,
    curBalance,
    prevBlock,
    curBlock
);
```

---

### **2. NymphEchoResponder.sol**

Emits an `EchoIncident` event when anomalies are detected:

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

* Only emits events; **no imperative logic**.
* ABI matches the trap payload exactly (8 arguments).

**Deployed Address:** `0xBD8048d93efa26ef3f986f2fe1Eb74E2b7c5D5be`

---

## **Deployment Instructions**

1. Setup `.env`:

```env
ETH_RPC_URL=<your-eth-rpc>
DROSERA_RPC_URL=<your-drosera-relay>
PRIVATE_KEY=<your-private-key>

RESPONSE_CONTRACT=<deployed responder address>
```

2. Compile and deploy:

```bash
forge script script/DeployAll.s.sol:DeployAll \
  --rpc-url $ETH_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY
```

3. Record deployed addresses in `.env` and `drosera.toml`.

---

## **drosera.toml Example**

```toml
[traps.nymph_echo]
path = "out/NymphEchoTrap.sol/NymphEchoTrap.json"
response_contract = "0x311cc11b6eB48edf199aE23b73130397A50232dC"
response_function = "respondWithEchoAlert(address,address,bytes32,bytes32,uint256,uint256,uint256,uint256)"
cooldown_period_blocks = 20
min_number_of_operators = 1
max_number_of_operators = 3
block_sample_size = 2
private_trap = true
whitelist = ["0x14e424df0c35686cf58fc7d05860689041d300f6"]
```

* `block_sample_size = 2` → compares newest vs previous sample only.
* `private_trap = true` → restricts usage to your whitelist.
* `whitelist` → list of Drosera operators allowed to execute the trap.

---

## **Best Practices**

* Always use **checksummed addresses** for `TARGET` and `WATCH`.
* Keep **trap/responder ABI aligned** to prevent reverts.
* Ensure **planner-safe checks** for empty or insufficient samples.
* Update **payload fields** if the responder function changes.

---

## **About**

NymphEchoTrap is a **reference Drosera trap**, implementing best practices for stateless, deterministic monitoring.
It reflects **Bjorn’s corrections** and is suitable for secure deployment, private traps, and reproducible anomaly detection.

---

Perfect! I can add a **workflow diagram** using Markdown-friendly ASCII arrows so it’s fully viewable on GitHub. Here’s the updated README section with the diagram included:

---

## **Workflow Diagram**

```text
+----------------+      collect()       +-----------------+
|  Drosera Relay |--------------------->| NymphEchoTrap   |
|   (scheduler)  |                      |  collect()      |
+----------------+                      +-----------------+
                                                  |
                                                  v
                                      Snapshot of TARGET/WATCH:
                                      - codehash
                                      - balance
                                      - block number
                                                  |
                                                  v
                                       +------------------+
                                       | shouldRespond()  |
                                       |  Compare newest  |
                                       |  vs previous     |
                                       |  samples         |
                                       +------------------+
                                                  |
                                    Anomaly detected? (code, balance, block)
                                                  |
                      +---------------------------+---------------------------+
                      |                                                       |
                     YES                                                      NO
                      |                                                       |
                      v                                                       v
           +--------------------+                                +-------------------+
           | Encode Payload      |                                | Return false,     |
           | (8 fields)          |                                | empty bytes       |
           +--------------------+                                +-------------------+
                      |
                      v
           +--------------------+
           | Drosera Relay      |
           | Calls Responder    |
           +--------------------+
                      |
                      v
           +--------------------+
           | NymphEchoResponder |
           | Emits EchoIncident |
           +--------------------+
```

**Explanation:**

1. **collect()**: Takes a deterministic snapshot of the `TARGET` and `WATCH` addresses (codehash, balance, block).
2. **shouldRespond()**: Compares newest vs previous sample; triggers only if anomaly detected.
3. **Payload**: Encodes exactly 8 fields to match the responder signature.
4. **Drosera Relay**: Handles the call to the responder securely.
5. **Responder**: Emits `EchoIncident` event to log the anomaly.

---