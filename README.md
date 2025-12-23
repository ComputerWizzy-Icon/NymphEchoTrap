# **NymphEchoTrap**

**Status:** Drosera-compatible stateless trap  
**Author:** Sekani chief JayCool BFF  
**Version:** 1.3 (Bjorn-reviewed & deploy-ready)

---

## **Overview**

`NymphEchoTrap` is a **stateless, deterministic Drosera trap** designed to detect critical anomalies in Ethereum contracts. It monitors:

* **Code changes** (`codehash` of TARGET)
* **Balance shifts** (ETH balance deviations of TARGET)
* **Block regressions** (new sample block < previous block)

The trap ensures **planner-safe execution**, **ABI alignment**, and **private trap compatibility**. It separates **collection**, **detection**, and **response** responsibilities, relying on the Drosera relay for secure, deterministic invocation.

**Note (Bjorn):**

* Replace `TARGET` and `WATCH` with **contract addresses** for production.
* `WATCH` currently serves as a **context/observer address** in the payload.

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
   * Early guard prevents execution if `TARGET` or `WATCH` is `0x0`.

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
````

**collect()**

* Takes a snapshot of `TARGET` and `WATCH`:

```solidity
// Early safety guard
if (TARGET == address(0) || WATCH == address(0)) return bytes("");

bytes32 codeh;
assembly { codeh := extcodehash(TARGET) }
uint256 bal = TARGET.balance;
uint256 blk = block.number;

return abi.encode(codeh, bal, blk);
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

* Includes **guard check** for malformed payloads (minimum 96 bytes per sample):

```solidity
if (data.length < 2 || data[0].length < 96 || data[1].length < 96) {
    return (false, bytes(""));
}
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

**Deployed Responder Address:** `0xaddC277b2A4511bCb86a479207C0E335AD5BFEbd`
**Deployed Trap Address:** `0x7cDcf1C4f4bfe5976f03317E51Be52530cB22983`

---

## **Deployment Instructions**

1. Setup `.env`:

```env
ETH_RPC_URL=<your-eth-rpc>
DROSERA_RPC_URL=<your-drosera-relay>
PRIVATE_KEY=<your-private-key>

RESPONSE_CONTRACT=0xaddC277b2A4511bCb86a479207C0E335AD5BFEbd
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
response_contract = "0xaddC277b2A4511bCb86a479207C0E335AD5BFEbd"
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
* Use **contract addresses** for TARGET in production (not EOAs) to detect code changes.

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

`NymphEchoTrap` is a **reference Drosera trap**, implementing best practices for stateless, deterministic monitoring.
It reflects **Bjorn’s corrections** and is suitable for **secure deployment**, **private traps**, and reproducible **anomaly detection**.

```
