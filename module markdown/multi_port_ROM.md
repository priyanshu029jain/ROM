# 📋 Module Specifications: Pure Asynchronous Multi-Port ROM

- **Source File:** `multi_port_ROM.v`

---

## 📐 Block Diagram

Below is the vectorized multi-port block diagram interface showing the single packed bus layout for multi-channel concurrent, zero-latency combinational lookups:

![Diagram](multi_port_ROM.svg "Multi-Port Asynchronous ROM Block Diagram")

---

## ⚙️ Design Parameters (Generics)

This module utilizes generic parameters to configure input/output bit vectors and scale the replication layout of the parallel read channels:

| Generic name | Type | Default Value | Description |
| ------------ | ---- | ------------- | ----------- |
| `data_width`   | `integer` | `8`           | Individual bit width of a single data word (byte-aligned by default). |
| `memory_size`  | `integer` | `8`           | Total depth allocation configuration of unique memory decoder choices. |
| `ports`        | `integer` | `4`           | Total capacity of parallel read channels enabled for simultaneous lookups. |

---

## 🔌 Interface Ports

Top-level component boundaries tracking multi-channel address inputs and parallel data output buses packed into high-density vector rows:

| Port name | Direction | Type | Description |
| --------- | --------- | ----------------- | ----------- |
| `cs`        | input     | `wire`            | Active-high Chip Select logic gating the localized combinational decoder tree. |
| `rd_en`     | input     | `wire`            | Active-high Read Enable control line validating immediate data evaluation loops. |
| `addr`      | input     | `wire [addr_bites -1:0]` | **Vectorized Address Input:** Packed vector containing `ports` x `$clog2(memory_size)` address fragments aligned side-by-side. |
| `data`      | output    | `reg [data_bites -1:0]`  | **Vectorized Data Output:** Packed combinational output wire bus containing all parallel decoded data chunks. |

---

## 💎 Internal Design Primitives

### Derived Constants (Localparams)
* `addr_width` = `$clog2(memory_size)` *(Calculates the structural address bit depth requirement per port layout)*
* `addr_bites` = `ports * addr_width` *(Total bit width of the packed address collection bus)*
* `data_bites` = `ports * data_width` *(Total bit width of the packed output collection bus)*

### Internal Storage & Tracking Matrices
* `i` (`integer`): Multi-purpose loop iterator variable utilized by the combinational generating loop.

---

## ⚙️ Behavioral Processes

### `Asynchronous Combinational Multi-Port Case Lookup`
* **Sensitivity List:** `@(*)`
* **Type:** Combinational / Asynchronous (`always @(*)`)
* **Description:** Manages unclocked multi-channel case matching choices instantly, driving the output bus via combinational multiplexer trees without latching or flip-flop pipelines.
  * **Active Selection Evaluation:** Checks control pins `{cs, rd_en}`. If established at a valid `2'b11` state, an index pointer parses through all designated channels from `0` up to `ports - 1`.
  * **Bit-Slice Case Mapping:** Uses Verilog's indexed part-select operator (`+:`) to slice out localized address sets, evaluate them through a hardcoded multiplexer decoder array, and write the matching hex payload directly onto the corresponding segment of the output bus using blocking assignments:
    ```text
    addr[i*addr_width +: addr_width] ===> Combinational Multiplexer Tree ===> data[i*data_width +: data_width]
    ```
  * **Fallback Reset:** If selection conditions drop out of bounds or control flags are disabled, the entire packed output bus is completely zeroed out (`{data_bites{1'b0}}`) to prevent latch inference and isolate downstream routing logic.