# 📋 Module Specifications: Multi-Port ROM (Algorithmic Memory Array)

- **Source File:** `multi_port_ROM_memArray.v`

---

## 📐 Block Diagram

Below is the vectorized multi-port block diagram interface showing the single packed bus layout for multi-channel concurrent read actions:

![Diagram](multi_port_ROM_memArray.svg "Multi-Port Memory Array Block Diagram")

---

## ⚙️ Design Parameters (Generics)

This module utilizes generic variables to dynamically dimension the bus slices and word depths across parallel access channels:

| Generic name | Type | Default Value | Description |
| ------------ | ---- | ------------- | ----------- |
| `data_width`   | `integer` | `8`           | Individual bit width of a single data word (byte-aligned by default). |
| `memory_size`  | `integer` | `8`           | Total depth allocation configuration of unique memory array slots. |
| `ports`        | `integer` | `4`           | Total capacity of parallel read channels enabled for simultaneous lookups. |

---

## 🔌 Interface Ports

Top-level component layout tracking multi-channel addresses and output buses packed into single high-density signals:

| Port name | Direction | Type | Description |
| --------- | --------- | ----------------- | ----------- |
| `clk`       | input     | `wire`            | Global master clock triggering internal loop evaluations and output updates on the positive edge. |
| `cs`        | input     | `wire`            | Active-high Chip Select signal used to validate localized read routing layers. |
| `rd_en`     | input     | `wire`            | Active-high Read Enable control gating internal storage lookups. |
| `addr`      | input     | `wire [addr_bites -1:0]` | **Vectorized Address Input:** Packed vector containing `ports` x `$clog2(memory_size)` address fragments aligned side-by-side. |
| `data`      | output    | `reg [data_bites -1:0]`  | **Vectorized Data Output:** Packed synchronous destination vector containing all parallel data chunks driven out of memory. |

---

## 💎 Internal Design Primitives

### Derived Constants (Localparams)
* `addr_width` = `$clog2(memory_size)` *(Calculates the address bit depth requirement)*
* `addr_bites` = `ports * addr_width` *(Total bit width of the packed address coordinates bus)*
* `data_bites` = `ports * data_width` *(Total bit width of the packed output collection bus)*

### Internal Storage & Tracking Matrices
* `mem_array` (`reg [data_width-1:0] mem_array [0:memory_size-1]`): Register array modeling the localized internal storage space.
* `i` (`integer`): Multi-purpose loop iterator variable utilized by generating loops.

---

## ⚙️ Behavioral Processes

### `Synchronous Generation & Parallel Read Loop`
* **Sensitivity List:** `@(posedge clk)`
* **Type:** Synchronous (`always @(posedge clk)`)
* **Description:** Manages internal pattern updates and sweeps across the vectorized ports on every active clock edge.
  * **Algorithmic Fill Loop:** Runs an internal loop from `0` to `memory_size - 1` to continually calculate value distributions inside `mem_array`. The formula generates a specific value pattern masked to the chosen `data_width`:
    $$\text{mem\_array}[i] = (16 \times i + i) \ \& \ \text{bitmask}$$
  * **Active Selection Evaluation:** Checks control pins `{cs, rd_en}`. If established at a valid `2'b11` state, an index pointer parses through all designated channels from `0` up to `ports - 1`.
  * **Bit-Slice Slicing Logic:** Uses Verilog's indexed part-select operator (`+:`) to isolate localized bit ranges and move data chunks from the generated array slots directly onto the synchronous output bus:
    $$\text{data}[i \times \text{data\_width} +: \text{data\_width}] \leftarrow \text{mem\_array}[\text{addr}[i \times \text{addr\_width} +: \text{addr\_width}]]$$
  * **Fallback Reset:** If selection drops out of bounds, the entire packed output register bus is zeroed out (`{data_bites{1'b0}}`) to secure pipeline isolation.