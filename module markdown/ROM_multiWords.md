# 📋 Module Specifications: Multi-Port Block-Structured ROM

- **Source File:** `ROM_multiWords.v`

---

## 📐 Block Diagram

Below is the multi-port memory boundary layout mapping out packed, high-density vector signal streaming paths:

![Diagram](ROM_multiWords.svg "Multi-Port Multi-Word ROM Block Diagram")

---

## ⚙️ Design Parameters (Generics)

This highly dynamic configuration profile maps memory blocks exactly to standard cache line architectures:

| Generic name | Type | Default Value | Description |
| ------------ | ---- | ------------- | ----------- |
| `WORD_SIZE`    | `integer` | `1`           | Data width of an individual word expressed in bytes. |
| `BLOCK_SIZE`   | `integer` | `4`           | The structural payload depth of a single block (number of words per cache line). |
| `RAM_BLOCKS`   | `integer` | `8`           | Total depth allocation tracking unique multi-word blocks inside the ROM. |
| `PORTS`        | `integer` | `4`           | Total capacity of independent concurrent lookup channels. |

---

## 🔌 Interface Ports

Top-level component layout tracking multi-channel address parameters and parallel output vectors:

| Port name | Direction | Type | Description |
| --------- | --------- | -------------------------------- | ----------- |
| `clk`            | input     | `wire`                           | Master global clock line driving synchronous register outputs on the positive edge. |
| `cs`             | input     | `wire`                           | Active-high Chip Select validation line enabling execution decoders. |
| `rd_en`          | input     | `wire`                           | Active-high Read Enable line gating memory block extraction logic. |
| `address_vector` | input     | `wire [address_vector_width -1:0]` | **Vectorized Address Input:** Packed vector grouping parallel address indices side-by-side. |
| `data_vector`    | output    | `reg [data_vector_width -1:0]`   | **Vectorized Data Output:** Packed synchronous register bus returning parallel extracted words. |

---

## 💎 Internal Design Primitives

### Derived Constants (Localparams)
* `word_width` = `WORD_SIZE * 8` *(Total bit width of an individual word unit)*
* `block_width` = `BLOCK_SIZE * word_width` *(Total bit width of an entire storage line/block)*
* `address_width` = `$clog2(RAM_BLOCKS * BLOCK_SIZE)` *(Total address bit resolution required to pinpoint an item)*
* `data_width` = `word_width` *(Bit width of the isolated output bus lane per channel)*
* `address_vector_width` = `PORTS * address_width` *(Total packed size of the combined input address bus)*
* `data_vector_width` = `PORTS * data_width` *(Total packed size of the combined output data bus)*
* `offset_width` = `$clog2(BLOCK_SIZE)` *(Bit slice selection width tracking words within a block)*
* `block_no_width` = `$clog2(RAM_BLOCKS)` *(Bit selection width used to target a main block address entry)*

### Internal Storage Arrays
* `mem_array` (`reg [block_width -1:0] mem_array [0:RAM_BLOCKS -1]`): Memory matrix holding wide block entries loaded via static external setups.
* `i` (`integer`): Multi-purpose loop iterator tracking concurrent channel operations.

---

## ⚙️ Core Logic Functions

### `d_out`
* **Input arguments:** `[address_width-1:0] addr`
* **Return type:** `[data_width-1:0]` (One isolated word)
* **Description:** Localized hardware mapping function that splits a flat lookup address into block targets and structural word offsets:
  1. **Address Parsing:** Slices out the lower bits for block offset placement tracking, using the upper remaining bits to calculate the row target index:
     $$\text{block\_no} = \text{addr}[\text{address\_width}-1 : \text{offset\_width}]$$
     $$\text{block\_offset} = \text{addr}[\text{offset\_width}-1 : 0]$$
  2. **Memory Row Fetch:** Grabs the wide multi-word string from the storage register array (`mem_array[block_no]`).
  3. **Bit-Slice Extraction:** Uses the indexed part-select operator (`+i`) to extract the exact targeted word segment and return it cleanly to the loop executor.

---

## ⚙️ Behavioral Processes

### `Static File Pre-Load Sequence`
* **Trigger condition:** `initial block`
* **Description:** Leverages the synthesizable system utility `$readmemh` to read the system text data configuration from the active path (`external_storage.mem`) and pre-load all entry indexes directly into `mem_array` blocks before runtime execution loops start.

### `Synchronous Multi-Channel Block Parsing Read`
* **Sensitivity List:** `@(posedge clk)`
* **Type:** Synchronous (`always @(posedge clk)`)
* **Description:** Evaluates lookups synchronously on every rising clock edge.
  * **Condition Check:** Evaluates active control flags `{cs, rd_en}`. If established at `2'b11`, a loop structures parallel channel assignments from `0` to `PORTS - 1`.
  * **Vector Execution Layer:** For each port lane, it extracts the matching address chunk from the input bus vector, pipes it into the processing function `d_out`, and updates the corresponding target data slice synchronously:
    ```text
    address_vector slice ---> d_out() Function Decoder ---> data_vector registered slice
    ```
  * **Fallback Reset:** If controls are disabled or drops low, the output data bus is zeroed out completely (`{data_vector_width{1'b0}}`) to secure pipeline validation.