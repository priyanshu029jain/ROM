# 📋 Module Specifications: Parameterized Multi-Port ROM

- **Source File:** `multi_port_ROM_externalStorage.v`

---

## 📐 Block Diagram

Below is the highly flexible, vector-packed multi-port block diagram interface showing vectorized routing boundaries for multi-channel concurrent lookups:

![Diagram](multi_port_ROM_externalStorage.svg "Multi-Port Architectural Block Diagram")

---

## ⚙️ Design Parameters (Generics)

This component is fully parameterized, enabling single-cycle multi-lane bus execution matching dynamic cache sizing layers:

| Generic name | Type | Default Value | Description |
| ------------ | ---- | ---------------------- | ----------- |
| `data_width`   | `integer` | `8`                    | Individual bit width of a single data word (byte-aligned by default). |
| `memory_size`  | `integer` | `8`                    | Total allocation depth of unique memory locations stored in the ROM array. |
| `ports`        | `integer` | `4`                    | Parallel access channel capacity allowing concurrent lookups. |
| `file_path`    | `string`  | `"external_storage.mem"` | System path pointing to the hexadecimal file utilized to pre-load memory blocks. |

---

## 🔌 Interface Ports

Top-level component boundaries tracking continuous asynchronous configuration vectors packed into single physical bus ports:

| Port name | Direction | Type | Description |
| --------- | --------- | ----------------- | ----------- |
| `clk`       | input     | `wire`            | Global master clock signal triggering internal synchronous data transfers on the positive edge. |
| `cs`        | input     | `wire`            | Active-high Chip Select control enabling localized read validation decode matrices. |
| `rd_en`     | input     | `wire`            | Active-high Read Enable control gating internal storage lookups. |
| `addr`      | input     | `wire [addr_bites -1:0]` | **Vectorized Address Bus:** Single packed input containing `ports` x `$clog2(memory_size)` address fragments mapped side-by-side. |
| `data`      | output    | `reg [data_bites -1:0]`  | **Vectorized Output Data Bus:** Single packed synchronous destination vector containing parallel data segments driven out of memory. |

---

## 💎 Internal Design Primitives

### Derived Constants (Localparams)
* `addr_width` = `$clog2(memory_size)` *(Calculates the structural address bit depth requirement)*
* `addr_bites` = `ports * addr_width` *(Total width of the packed coordinate vector)*
* `data_bites` = `ports * data_width` *(Total width of the packed output collection vector)*

### Internal Storage & Tracking Matrices
* `mem_array` (`reg [data_width-1:0] mem_array [0:memory_size-1]`): Array modeling the internal physical ROM storage.
* `i` (`integer`): Internal loop iterator variable utilized by the generation block matrix.

---

## ⚙️ Behavioral Processes

### `Initialization Sequence`
* **Trigger condition:** `initial block`
* **Description:** Leverages the synthesizable system function `$readmemh` to read the payload text file target defined by `file_path` and seed the exact contents directly into the internal structural array slots (`mem_array`) before execution runtime commences.

### `Synchronous Multi-Port Matrix Read`
* **Sensitivity List:** `@(posedge clk)`
* **Type:** Synchronous (`always @(posedge clk)`)
* **Description:** Handles multi-channel access evaluation loops synchronously on every clock cycle.
  * **Active Condition:** Evaluates control flags `{cs, rd_en}`. If established at `2'b11`, a hardware-rolled parallel loop sweeps through all designated ports from `0` up to `ports - 1`.
  * **Bit-Slice Slicing Logic:** Uses Verilog's indexed part-select operator (`+:`) to cleanly extract localized address offsets and route the fetched contents back to the matching output vector slice coordinates:
    $$\text{data}[i \times \text{data\_width} +: \text{data\_width}] \leftarrow \text{mem\_array}[\text{addr}[i \times \text{addr\_width} +: \text{addr\_width}]]$$
  * **Fallback Reset:** If conditions drop out of selection bounds, the packed output bus is completely zeroed out (`{data_bites{1'b0}}`) to secure pipeline insulation against transient evaluation state errors.