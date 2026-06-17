# 📋 Module Specifications: Dynamic FSM-Controlled Multi-Port ROM

- **Source File:** `ROM.v`

---

## 📐 Block Diagram

Below is the updated module boundary layout showcasing independent port-aligned read enables (`rd`), vectorized buses, and handshaking lines:

![Diagram](ROM.svg "Multi-Port FSM ROM Block Diagram")

---

## ⚙️ Design Parameters (Generics)

This component uses generic variables to configure output dimensions and scale data-bus slicing parameters dynamically:

| Generic name | Type | Default Value | Description |
| ------------ | ---- | ------------- | ----------- |
| `WORD_SIZE`    | `integer` | `1`           | Data length of an individual word block expressed in bytes. |
| `BLOCK_SIZE`   | `integer` | `4`           | The structural payload depth of a single block line (number of words per cache line). |
| `RAM_BLOCKS`   | `integer` | `8`           | Total depth tracking unique multi-word storage slots within the ROM array. |
| `PORTS`        | `integer` | `4`           | Total number of independent parallel data access ports. |

---

## 🔌 Interface Ports

Top-level component boundaries managing independent port control strobes, multi-channel parsing indices, and dynamic execution flags:

| Port name | Direction | Type | Description |
| --------- | --------- | -------------------------------- | ----------- |
| `clk`            | input     | `wire`                           | Master global clock line driving sequential state registers on its rising edge. |
| `rd`             | input     | `wire [PORTS -1:0]`              | Independent active-high Read Enable control line assigned to each port channel. |
| `cs`             | input     | `wire`                           | Active-high Chip Select activation signal verifying memory matrix lookups. |
| `rst_n`          | input     | `wire`                           | Master system reset line (active-low tracking convention). |
| `address_vector` | input     | `wire [address_vector_width -1:0]` | **Vectorized Address Input:** Packed vector holding parallel coordinate addresses side-by-side. |
| `ready`          | output    | `reg`                            | Handshake status line signaling to the master interface that output data is valid. |
| `data_vector`    | output    | `reg [data_vector_width -1:0]`   | **Vectorized Data Output:** Packed output register bus returning decoded word arrays. |

---

## 💎 Internal Design Primitives

### Derived Constants (Localparams)
* `word_width` = `WORD_SIZE * 8` *(Total bit width of an individual word unit)*
* `block_width` = `BLOCK_SIZE * word_width` *(Total bit width of an entire storage block line)*
* `address_width` = `$clog2(RAM_BLOCKS * BLOCK_SIZE)` *(Total address bit depth required per port channel)*
* `data_width` = `word_width` *(Bit width of the isolated data lane per active port)*
* `address_vector_width` = `PORTS * address_width` *(Total packed size of the combined address bus)*
* `data_vector_width` = `PORTS * data_width` *(Total packed size of the combined data bus)*
* `offset_width` = `$clog2(BLOCK_SIZE)` *(Bit slice selection width tracking word offsets within a block)*
* `block_no_width` = `$clog2(RAM_BLOCKS)` *(Bit selection width used to target a block address entry)*

### State Machine Encoding
* `idle_state`  = `2'b00` *(Awaiting any read activation line while chip selection is high)*
* `fetch_state` = `2'b01` *(Deliberate single-cycle hardware stall mimicking physical cell access latencies)*
* `read_state`  = `2'b10` *(Slicing out targets per active port, driving output vector, and asserting `ready`)*

---

## ⚙️ Core Logic Functions

### `d_out`
* **Input arguments:** `[address_width-1:0] addr`, `read`
* **Return type:** `[data_width-1:0]` (One isolated word payload or a vector of zeros if disabled)
* **Description:** Localized mapping function that evaluates lookups on a port-by-port basis:
  1. **Active Port Check:** Evaluates the specific port's `read` bit signal. If low, it skips extraction and returns a safe default vector of zeros (`1'b0`) to avoid floating high-impedance artifacts inside internal logic.
  2. **Address Slicing:** Splits the input address chunk into structural block row entries and word offset indices:
     $$\text{block\_no} = \text{addr}[\text{address\_width}-1 : \text{offset\_width}]$$
     $$\text{block\_offset} = \text{addr}[\text{offset\_width}-1 : 0]$$
  3. **Word Extraction:** Fetches the matching multi-word block string from `mem_array[block_no]` and slices out the target data word using the indexed part-select operator (`+:`).

---

## 🕹️ Finite State Machine (FSM) Execution

The memory controller regulates its multi-channel pipeline through a 2-process Finite State Machine:

```text
       ┌───────────┐         ( |rd && cs)        ┌─────────────┐
------>│   IDLE    │────────────────────────────>│    FETCH    │
       │  (2'b00)  │<────────────────────────────│   (2'b01)   │
       └───────────┘         !(|rd && cs)        └─────────────┘
             ▲                                          │
             │                                          │ (Unconditional)
             │              ┌─────────────┐             │
             └──────────────│    READ     │<────────────┘
              !(|rd && cs)  │   (2'b10)   │
                            └─────────────┘
                                   │
                                   └─( |rd && cs)───> [Loops to FETCH]
```