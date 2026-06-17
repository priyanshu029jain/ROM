# 📋 Module Specifications: Pure Synchronous Multi-Port ROM

- **Source File:** `multi_port_ROM_sync.v`

---

## 📐 Block Diagram

Below is the vectorized multi-port block diagram interface showing the single packed bus layout for multi-channel concurrent synchronous lookups:

![Diagram](multi_port_ROM_sync.svg "Multi-Port Synchronous ROM Block Diagram")

---

## ⚙️ Design Parameters (Generics)

This module utilizes parameters to configure output widths, total addressable space, and the replication factor of parallel read channels:

| Generic name | Type | Default Value | Description |
| ------------ | ---- | ------------- | ----------- |
| `data_width`   | `integer` | `8`           | Individual bit width of a single data word (byte-aligned by default). |
| `memory_size`  | `integer` | `8`           | Total depth allocation configuration of unique memory positions. |
| `ports`        | `integer` | `4`           | Total capacity of parallel read channels enabled for simultaneous lookups. |

---

## 🔌 Interface Ports

Top-level component layout tracking multi-channel addresses and output buses packed into high-density vector signals:

| Port name | Direction | Type | Description |
| --------- | --------- | ----------------- | ----------- |
| `clk`       | input     | `wire`            | Global master clock triggering internal loop evaluations and synchronous register updates on the positive edge. |
| `cs`        | input     | `wire`            | Active-high Chip Select signal used to validate localized read routing layers. |
| `rd_en`     | input     | `wire`            | Active-high Read Enable control gating internal decoder matrix evaluation. |
| `addr`      | input     | `wire [addr_bites -1:0]` | **Vectorized Address Input:** Packed vector containing `ports` x `$clog2(memory_size)` address fragments aligned side-by-side. |
| `data`      | output    | `reg [data_bites -1:0]`  | **Vectorized Data Output:** Packed synchronous register bus containing all parallel data chunks driven out of memory. |

---

## 💎 Internal Design Primitives

### Derived Constants (Localparams)
* `addr_width` = `$clog2(memory_size)` *(Calculates the address bit depth requirement per port)*
* `addr_bites` = `ports * addr_width` *(Total bit width of the packed address coordinates bus)*
* `data_bites` = `ports * data_width` *(Total bit width of the packed output collection bus)*

### Internal Storage & Tracking Matrices
* `i` (`integer`): Multi-purpose loop iterator variable utilized by the concurrent generating loop.

---

## ⚙️ Behavioral Processes

### `Synchronous Multi-Port Case Lookup`
* **Sensitivity List:** `@(posedge clk)`
* **Type:** Synchronous (`always @(posedge clk)`)
* **Description:** Manages hardcoded multi-channel lookup operations synchronously on every rising clock edge without internal memory array (`reg`) storage overhead.
  * **Active Selection Evaluation:** Checks control pins `{cs, rd_en}`. If established at a valid `2'b11` state, an index pointer parses through all designated channels from `0` up to `ports - 1`.
  * **Bit-Slice Case Mapping:** Uses Verilog's indexed part-select operator (`+:`) to isolate localized address slices, decode them through an internal multiplexer tree, and register the matching hex payload directly onto the corresponding slice of the output bus using non-blocking assignments:
    ```text
    addr[i*addr_width +: addr_width] ===> Decode Array (8'hA5 to 8'h7E) ===> data[i*data_width +: data_width]
    ```
  * **Fallback Reset:** If selection drops out of bounds or control flags are disabled, the entire packed output register bus is cleanly zeroed out (`{data_bites{1'b0}}`) to secure pipeline insulation against floating data states.