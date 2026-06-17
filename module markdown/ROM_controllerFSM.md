# 📋 Module Specifications: Multi-Port ROM Memory Controller (FSM)

- **Source File:** `ROM_controllerFSM.v`

---

## 📐 Block Diagram

Below is the structural module boundary displaying control handshaking lines (`ready`), memory vector buses, and global state initialization pins:

![Diagram](ROM_controllerFSM.svg "ROM Controller FSM Block Diagram")

---

## ⚙️ Design Parameters (Generics)

This component uses design parameters to scale data path bit slices and coordinate block widths for cache interaction layers:

| Generic name | Type | Default Value | Description |
| ------------ | ---- | ------------- | ----------- |
| `WORD_SIZE`    | `integer` | `1`           | Individual width of a single data word unit expressed in bytes. |
| `BLOCK_SIZE`   | `integer` | `4`           | The structural payload depth of a block (number of words per memory line). |
| `RAM_BLOCKS`   | `integer` | `8`           | Total depth allocation tracking unique multi-word cache blocks in storage. |
| `PORTS`        | `integer` | `4`           | Parallel access capacity allowing concurrent multi-channel lookups. |

---

## 🔌 Interface Ports

Top-level component boundaries managing synchronous handshaking, multi-channel parsing inputs, and vector output signals:

| Port name | Direction | Type | Description |
| --------- | --------- | -------------------------------- | ----------- |
| `clk`            | input     | `wire`                           | Master global clock driving sequential state registers on the positive edge. |
| `rd`             | input     | `wire`                           | Active-high Read Enable control signal prompting a state transition. |
| `cs`             | input     | `wire`                           | Active-high Chip Select validation line enabling the controller matrix. |
| `rst_n`          | input     | `wire`                           | Active-low asynchronous/synchronous system master reset line. |
| `address_vector` | input     | `wire [address_vector_width -1:0]` | **Vectorized Address Input:** Packed vector grouping parallel target addresses side-by-side. |
| `ready`          | output    | `reg`                            | Handshake flag signaling that valid data output is present on the bus. |
| `data_vector`    | output    | `reg [data_vector_width -1:0]`   | **Vectorized Data Output:** Packed register bus returning parallel extracted words. |

---

## 💎 Internal Design Primitives

### Derived Constants (Localparams)
* `word_width` = `WORD_SIZE * 8` *(Total bit width of an individual word)*
* `block_width` = `BLOCK_SIZE * word_width` *(Total bit width of an entire memory block line)*
* `address_width` = `$clog2(RAM_BLOCKS * BLOCK_SIZE)` *(Address bit width required to target a specific word)*
* `data_width` = `word_width` *(Bit width of an isolated data lane per active port)*
* `address_vector_width` = `PORTS * address_width` *(Total width of the packed parallel address input)*
* `data_vector_width` = `PORTS * data_width` *(Total width of the packed parallel data output)*
* `offset_width` = `$clog2(BLOCK_SIZE)` *(Bit slice selection width tracking word offsets within a block)*
* `block_no_width` = `$clog2(RAM_BLOCKS)` *(Bit selection width used to target a block address entry)*

### State Machine Encoding
* `idle_state` = `2'b00` *(Awaiting valid chip selection and read assertions)*
* `fetch_state` = `2'b01` *(Cycle delay mimicking structural memory array lookups)*
* `read_state`  = `2'b10` *(Slicing out targets, driving output vector, and asserting `ready`)*

---

## ⚙️ Core Logic Functions

### `d_out`
* **Input arguments:** `[address_width-1:0] addr`
* **Return type:** `[data_width-1:0]` (One isolated word)
* **Description:** Hardware mapping function that parses an input address to fetch wide blocks and slice out the requested data word:
  1. **Address Parsing:** Slices out the lower bits for block offset tracking, while using the remaining upper bits to index the row:
     $$\text{block\_no} = \text{addr}[\text{address\_width}-1 : \text{offset\_width}]$$
     $$\text{block\_offset} = \text{addr}[\text{offset\_width}-1 : 0]$$
  2. **Memory Row Fetch:** Extracts the multi-word block string from the register array (`mem_array[block_no]`).
  3. **Bit-Slice Extraction:** Employs an indexed part-select operator (`+:`) to isolate the target word segment and pass it back to the FSM output decoder.

---

## 🕹️ Finite State Machine (FSM) Execution

The memory controller uses a 2-process Mealy/Moore hybrid Finite State Machine architecture to regulate read latencies safely:

```text
       ┌───────────┐         (rd && cs)         ┌─────────────┐
------>│   IDLE    │───────────────────────────>│    FETCH    │
       │  (2'b00)  │<───────────────────────────│   (2'b01)   │
       └───────────┘       !(rd && cs)          └─────────────┘
             ▲                                         │
             │                                         │ (Unconditional)
             │              ┌─────────────┐            │
             └──────────────│    READ     │<───────────┘
              !(rd && cs)   │   (2'b10)   │
                            └─────────────┘
                                   │
                                   └─(rd && cs)───> [Loops to FETCH]
``` 