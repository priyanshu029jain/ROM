# 📋 Module Specifications: dual_port_ROM

- **Source File:** `dual_port_ROM.v`

---

## 📐 Block Diagram

Below is the structural block diagram displaying the dual-port control interface lines, independent data output boundaries, and parallel address selection hooks for the read-only memory unit:

![Diagram](dual_port_ROM.svg "Architectural Module Diagram")

---

## 🔌 Interface Ports

Top-level module boundary pins enabling simultaneous, independent dual-address lookups when selected by the system matrix:

| Port name | Direction | Type          | Description |
| --------- | --------- | ------------- | ----------- |
| `addr1`   | input     | `wire [2:0]`  | 3-bit binary-encoded lookup address bus for Port 1, used to reference one of the 8 unique storage slots. |
| `addr2`   | input     | `wire [2:0]`  | 3-bit binary-encoded lookup address bus for Port 2, allowing parallel access to any of the 8 storage slots. |
| `rd_en`   | input     | `wire`        | Active-high read control signal validating processor execution access loops for both ports. |
| `cs`      | input     | `wire`        | Active-high Chip Select strobe enabling the module's localized combinational routing layers. |
| `data1`   | output    | `reg [7:0]`   | 8-bit output data bus routing the literal byte segment requested by `addr1` back to the network interface. |
| `data2`   | output    | `reg [7:0]`   | 8-bit output data bus routing the literal byte segment requested by `addr2` back to the network interface. |

---

## ⚙️ Behavioral Processes

The core storage array is mirrored combinational logic across two concurrent hardware lookup ports, allowing two separate execution segments to read data at the exact same time without bank conflicts or arbitration stalls.

### `1st port lookup`
* **Sensitivity List:** `@(*)`
* **Type:** Combinational (`always @(*)`)
* **Description:** Asynchronous lookup decoder tree evaluating active line signals to drive the first data bus (`data1`).
  * **Condition Check:** Concatenates control primitives (`{cs, rd_en}`). If the resulting bit vector matches a valid `2'b11` state, the internal combinational multiplexer layout decodes the value of `addr1` to pull out the hardcoded 8-bit hex payload (`8'hA5` to `8'h7E`).
  * **Fallback / Idle State:** If either control line drops low or the address falls out of bounds, the process hits its structural safety fallback block and forces `data1` to a steady default of `8'h00`.

### `2nd port lookup`
* **Sensitivity List:** `@(*)`
* **Type:** Combinational (`always @(*)`)
* **Description:** Asynchronous lookup decoder tree evaluating active line signals to drive the second data bus (`data2`).
  * **Condition Check:** Evaluates the identical control vector (`{cs, rd_en} == 2'b11`). When active, it references the shared memory array content using the separate `addr2` address lines to output the targeted data onto `data2`.
  * **Fallback / Idle State:** If control flags drop or become invalid, it forces `data2` directly to `8'h00` as a structural safety fallback.