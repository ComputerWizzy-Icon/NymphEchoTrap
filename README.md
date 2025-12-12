# **NymphEchoTrap**

**Status:** Drosera-compatible stateless trap
**Author:** Sekani chief JayCool BFF
**Version:** 1.2 (Bjorn-reviewed & corrected)

---

## **Overview**

`NymphEchoTrap` is a **stateless, deterministic Drosera trap** designed to detect critical anomalies in Ethereum contracts. It monitors:

* **Code changes** (`codehash` of TARGET)
* **Balance shifts** (ETH balance deviations of TARGET)
* **Block regressions** (new sample block < previous block)

The trap ensures **planner-safe execution**, **ABI alignment**, and **private trap compatibility**. It separates **collection**, **detection**, and **response** responsibilities, relying on the Drosera relay for secure, deterministic invocation.

**Note (Bjorn):**

* Replace placeholder `TARGET` and `WATCH` addresses before deployment.
* Monitor **TARGET.balance** if intended; currently WATCH.balance is in the template.

---

## **Key Improvements (Bjorn Review)**

1. **ABI Alignment**

   * Payload matches responder’s **exact 8-argument signature**.
   * Removed extra `reason` argument to avoid decode mismatches.

2. **Deterministic collect()**

   * Snapshot uses only `TARGET` and `WATCH` constants.
   * No `msg.sender` or `address(this)`.

3. **Block Progression Check**

   * Detects **true block regressions** (`<`) instead of `<=`.

4. **Planner-Safety Guard**

   * Skips execution if fewer than 2 samples or malformed samples.

5. **Cleaner Payload Encoding**

   * Encodes exactly 8 fields:
     `TARGET, WATCH, prevCode, curCode, prevBalance, curBalance, prevBlock, curBlock`

---

## **Features**

* Stateless, no on-chain storage.
* Deterministic execution across all Drosera operators.
* Private trap support with operator whitelist.
* Generates precise payloads for responders, avoiding false positives.
* Safe handling of empty or malformed data.

---

## **Contract Architecture**

### **1. NymphEchoTrap.sol**

Implements `ITrap` interface:

```solidity
function collect() external view returns (bytes);
function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
```

**collect()**

* Takes a snapshot of `TARGET` and `WATCH`:

```solidity
bytes32 codeh;
assembly { codeh := extcodehash(TARGET) }
return abi.encode(codeh, TARGET.balance, block.number);
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

* Includes **guard check** for malformed payloads (minimum 96 bytes per sample).

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

**Deployed Address:** `0x44a481Ec90bB56B2604A1ca73822D9eCE12D8aa0`

---

## **Deployment Instructions**

1. Setup `.env`:

```env
ETH_RPC_URL=<your-eth-rpc>
DROSERA_RPC_URL=<your-drosera-relay>
PRIVATE_KEY=<your-private-key>

RESPONSE_CONTRACT=0x44a481Ec90bB56B2604A1ca73822D9eCE12D8aa0
```

2. Compile and deploy:

```bash
forge script script/DeployAll.s.sol:DeployAll \
  --rpc-url $ETH_RPC_URL \
  --broadcast \
  --private-key $PRIVATE_KEY
```

3. Update `drosera.toml` with deployed addresses and payload config.

---

## **drosera.toml Example**

```toml
[traps.nymph_echo]
path = "out/NymphEchoTrap.sol/NymphEchoTrap.json"
response_contract = "0x44a481Ec90bB56B2604A1ca73822D9eCE12D8aa0"
response_function = "respondWithEchoAlert(address,address,bytes32,bytes32,uint256,uint256,uint256,uint256)"
cooldown_period_blocks = 20
min_number_of_operators = 1
max_number_of_operators = 3
block_sample_size = 2
private_trap = true
whitelist = ["0x14e424df0c35686cf58fc7d05860689041d300f6"]
```

* `block_sample_size = 2` → compares newest vs previous sample only.
* `private_trap = true` → restricts execution to your whitelist.

---

## **Best Practices**

* Use **checksummed addresses** for `TARGET` and `WATCH`.
* Keep **trap/responder ABI aligned** to prevent decode errors.
* Ensure **planner-safe checks** for empty or insufficient samples.
* Update **payload fields** if the responder function changes.

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

---

## **About**

NymphEchoTrap is a **reference Drosera trap**, implementing best practices for stateless, deterministic monitoring.
It reflects **Bjorn’s corrections** and is suitable for secure deployment, private traps, and reproducible anomaly detection.

---
