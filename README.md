# 🗄️ Multi-Port Parameterized ROM IP Core Development Kit

A highly versatile, parameterized, and comprehensive suite of **Read-Only Memory (ROM)** architectures implemented in synthesizable **Verilog (IEEE 1364-2005)**. This repository serves as a professional-grade IP development vault, containing modular ROM primitives scaled from single-port asynchronous structures up to full **Finite State Machine (FSM)-driven Multi-Port Block memory controllers**. 

This IP subsystem is designed specifically to interface with multi-level cache hierarchies ($RAM \rightarrow L3 \rightarrow L2 \rightarrow L1 \rightarrow \text{Register File}$), functioning as a flexible data provider modeling real-world memory access latencies, word-slice extraction, and vectorized address routing.

---

## 📂 Repository Architecture & Directory Structure

The repository workspace follows industry-standard Electronic Design Automation (EDA) project layouts, isolating structural design files from verification modules, waveforms, and automated Markdown documentation.

```text
ROM/
├── .gitignore                  # Excludes transient compilation artifacts (*.vvp, *.vcd)
├── external_storage.mem        # External hex data image file to pre-load arrays
├── README.md                   # Core repository overview & system guide
├── ROM.md                      # Detailed technical manual for the master FSM ROM controller
├── ROM.svg                     # Structural block diagram for the master FSM ROM controller
├── ROM.v                       # Master design: Parameterized, FSM-driven, Multi-Port ROM
├── testbench.v                 # Master simulation suite driving test vectors
├── testbench.vcd               # Value Change Dump waveform trace file
├── testbench.vvp               # Compiled Icarus Verilog simulation runtime executable
├── waveform_ROM.png            # Master FSM simulation trace visualization
│
├── 📁 module markdown/         # Automated Technical Specification Sheets
│   ├── multi_port_ROM_sync.svg
│   ├── multi_port_ROM.md
│   ├── multi_port_ROM.svg
│   ├── ROM_controllerFSM.md
│   ├── ROM_controllerFSM.svg
│   ├── ROM_multiWords.md
│   ├── ROM_multiWords.svg
│   ├── single_port_ROM.md
│   └── single_port_ROM.svg
│
├── 📁 rtl design/              # Synthesizable Hardware Source Core Files
│   ├── dual_port_ROM.v         # Dual-independent combinational read port ROM
│   ├── multi_port_ROM_externalStorage.v # Multi-port ROM seeded via $readmemh
│   ├── multi_port_ROM_memArray.v        # Multi-port ROM seeded via algorithmic loop
│   ├── multi_port_ROM_sync.v   # Synchronously registered case-statement multi-port ROM
│   ├── multi_port_ROM.v        # Pure combinational case-statement multi-port ROM
│   ├── ROM_controllerFSM.v     # Basic FSM-regulated multi-port block memory unit
│   ├── ROM_multiWords.v        # Multi-word block structured ROM with function parsing
│   └── single_port_ROM.v       # Baseline 1-Port asynchronous lookup core
│
└── 📁 waveforms/               # Functional Verification Trace Images
    ├── dual_port_ROM.png
    ├── multi_port_ROM_externalStorage.png
    ├── multi_port_ROM_memArray.png
    ├── multi_port_ROM_sync.png
    ├── multi_port_ROM.png
    ├── ROM_controllerFSM.png
    ├── ROM_multiWords.png
    └── single_port_ROM.png

``` 

### 🏗️ Architectural Topology Matrix

This development kit documents the evolution of custom memory structures across three distinct design paradigms:

#### 1. Primitives Layer (`single_port_ROM.v`, `dual_port_ROM.v`)

* **Asynchronous Lookup Matrices:** Implements single/dual combinational ports reading directly from hardcoded address-to-data decode trees.
* **Characteristics:** Zero clock-cycle propagation delay; absolute minimal silicon area overhead.

#### 2. Vectorized Multi-Port Layer (`multi_port_ROM*.v`, `ROM_multiWords.v`)

* **Packed Address/Data Vector Rails:** Concatenates individual, isolated address and data channels into a single high-density bus vector (`[address_vector_width-1:0]`) to optimize routing lanes.
* **Cache Line Extraction:** Replicates physical memory block granularities (`BLOCK_SIZE`, `WORD_SIZE`) and isolates requested memory words using hardware bit-slice indexing part-selects (`+:`) driven by an internal parsing evaluation helper function (`d_out`).

#### 3. Latency-Matched FSM Layer (`ROM_controllerFSM.v`, `ROM.v`)

* **Physical Memory Interconnect Emulation:** Employs a robust, synthesizable 2-process Finite State Machine (FSM) tracking an structural pipeline route ($IDLE \rightarrow FETCH \rightarrow READ$).
* **Handshaking Mechanics:** Deliberately stalls pipeline delivery by a targeted single clock tick (`FETCH_STATE`) to mimic capacitive word-line/bit-line charge settlement delays and propagation latencies inherent in physical ASIC macrocells or FPGA block RAM (BRAM) units. Asserting a synchronous `ready` handshake strobe only when the output data bitstream is completely stable.

## 📦 RTL Module Short Specifications

This section provides a high-level structural overview of the active cores available within the `rtl_design/` directory. For deep architectural reviews, timing parameters, and internal primitive structures, select the redirect links to view their dedicated specification markdown files.

---

### 1. Baseline Primitives

#### 🔹 [Single-Port ROM (`single_port_ROM.v`)](../module%20markdown/single_port_ROM.md)

* **Description:** A baseline, 1-port asynchronous lookup cell that maps flat inputs to static data outputs instantly without sequential logic overhead.
* **Interface Profile:** Asynchronous, Single Address, Single Data Port.

#### 🔹 [Dual-Port ROM (`dual_port_ROM.v`)](../module%20markdown/single_port_ROM.md) *(Uses matching layout primitives)*

* **Description:** Implements two completely independent parallel combinational read ports, allowing two separate bus master nodes to query the same memory array concurrently without structural hazards.
* **Interface Profile:** Dual Asynchronous Address Inputs, Dual Data Outputs.

---

### 2. Packed Vector Cores

#### 🔹 [Combinational Multi-Port ROM (`multi_port_ROM.v`)](../module%20markdown/multi_port_ROM.md)

* **Description:** Packs all parallel port lines into uniform, high-density vector rows. Uses an unclocked combinational block (`always @(*)`) and blocking assignments to achieve simultaneous multi-channel lookups with zero clock-cycle propagation delay.
* **Interface Profile:** `PORTS`-scaled packed address input and data output rails.

#### 🔹 [Synchronous Multi-Port ROM (`multi_port_ROM_sync.v`)](../module%20markdown/multi_port_ROM_sync.md)

* **Description:** A synchronously registered multi-channel lookup block. It samples the entire packed vector address bus on the positive edge of the clock (`always @(posedge clk)`) and drives clean, glitch-free data outputs through registered multiplexer trees.
* **Interface Profile:** Synchronous clocked execution, packed address/data vectors.

#### 🔹 [Multi-Word Block ROM (`ROM_multiWords.v`)](../module%20markdown/ROM_multiWords.md)

* **Description:** Moves away from a flat index layout to mimic a high-performance **cache line structure**. The internal logic uses a hardware function (`d_out`) to parse flat addresses into distinct block numbers and local word offsets, slicing out data using indexed part-selects (`+:`).
* **Interface Profile:** Parameterized `BLOCK_SIZE` and `WORD_SIZE` configuration vectors.

---

### 3. FSM-Managed Subsystems

#### 🔹 [Basic ROM Controller FSM (`ROM_controllerFSM.v`)](../module%20markdown/ROM_controllerFSM.md)

* **Description:** Integrates a basic 2-process Finite State Machine (FSM) over the block memory core to regulate data path setup delays. It transitions through a structured pipeline to guarantee signal stabilization before declaring data valid.
* **Interface Profile:** Synchronous state routing, single `rd` strobe, handshaking `ready` bit.

#### 🔹 [Master FSM Multi-Port ROM (`ROM.v`)](../ROM.md) *(Master Design Core)*

* **Description:** The most advanced subsystem core in the toolkit. It combines full cache-line address parsing (`d_out`), high-density packed vector buses, and a multi-channel active-low reset layout (`!rst_n`). An OR-reduction routing check (`|rd`) evaluates whether *any* channel is active, stalling the pipeline in `FETCH_STATE` for precisely one clock cycle to mimic physical memory charge settlement latencies before safely outputting stable data.
* **Interface Profile:** Complete interface including per-port `rd` bits, active-low reset, master `ready` handshake, and parameterized multi-word block tracking.

### 🔌 Standardized I/O Pin Boundary Signals

The core IP blocks manage external module handshaking and interface routing using the following standardized pin mapping configurations:

| Port Name | Direction | Data Type | Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | `wire` | Master global system clock driving internal FSM sequential transitions on its rising edge. |
| `rst_n` | Input | `wire` | Master asynchronous/synchronous system reset line conforming to standard active-low convention. |
| `cs` | Input | `wire` | Active-high Chip Select validation line used to activate the internal look-up matrix or controller matrix. |
| `rd` | Input | `wire [PORTS-1:0]` | Parallel array of independent active-high Read Enable lines tracking incoming transaction requests per port channel. |
| `address_vector` | Input | `wire [address_vector_width-1:0]` | **Vectorized Input Bus:** High-density packed vector grouping parallel port address coordinates side-by-side. |
| `ready` | Output | `reg` | Synchronous handshake validation strobe confirming that target data has settled and is completely stable on the output rail. |
| `data_vector` | Output | `reg [data_vector_width-1:0]` | **Vectorized Output Bus:** High-density packed destination register vector delivering all decoded multi-channel words simultaneously. |

## 🕹️ Deep-Dive: Why an FSM Memory Controller?

In an idealized simulation, memory lookups appear instantaneous. In real silicon, however, a ROM is a massive, dense physical matrix of intersecting wires (**word-lines** and **bit-lines**) and pull-down transistors that suffer from significant **parasitic RC delays** and analog voltage fluctuations. 

Without a structured Finite State Machine (FSM), simultaneous multi-port requests would cause address glitches, race conditions, and massive power spikes, leading to data corruption. The 3-state FSM acts as a hardware traffic controller, orchestrating internal analog timings before signaling to the system that data is safe to capture.

---

## 🔬 Silicon Behavior Across FSM States

The controller synchronizes memory operations through three distinct pipelined states:

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

### 1. IDLE State (`2'b00`) — Standby & Pre-charge

* **Silicon Action:** Drives all out-bound data rails to zero, completely preventing downstream combinational logic gates from toggling wastefully. Inside the macrocell matrix, internal pull-up transistors engage to pump the highly capacitive bit-lines up to a full baseline supply voltage ($V_{DD}$).
* **Purpose:** Minimizes dynamic power leakage ($I_{\text{dynamic}}$) during idle cycles and pre-charges baseline cell voltages to ensure rapid evaluation in the subsequent phases.

### 2. FETCH State (`2'b01`) — The Intentional Hardware Stall

* **Silicon Action:** Incoming address vectors stabilize at the primary row decoders, driving a single physical word-line high. Because the internal column lines are highly capacitive, the FSM inserts an intentional stall for one full clock cycle. This allows the miniature access transistors within the selected memory cells sufficient time to sink current and cleanly discharge the heavy bit-lines to ground.
* **Purpose:** Overcomes physical wire RC propagation delays and analog settlement latencies. This architectural boundary prevents the system from latching unstable, meta-stable, or corrupted intermediate data.

### 3. READ State (`2'b10`) — Word Extraction & Handshake

* **Silicon Action:** Dedicated internal sense amplifiers lock onto the fully stabilized differential bit-line voltages, snapping them to crisp digital logic levels. The structural `d_out` hardware function evaluates the lower address offset bits to slice the specific word payload out of the wider macrocell cache block line. Concurrently, the external `ready` pin is driven active-high.
* **Purpose:** Delivers a clean, glitch-free data vector to the system bus alongside a synchronous validation signal, indicating to downstream bus masters (such as a CPU execution unit) that the payload is stable and safe to latch. 

## 🛠️ Toolchain & EDA Tools

This project was developed, simulated, and documented using the following industrial and open-source hardware engineering tool suite:

* **Design & IDE:** [VS Code](https://code.visualstudio.com/) — Integrated development environment used for writing synthesizable RTL code.
* **Documentation Engine:** [TerosHDL](https://teroshdl.github.io/teroSHDL/) — Used for real-time code parsing, block diagram schematic generation, and automated markdown documentation formatting.
* **Simulation & Synthesis Compiler:** [Icarus Verilog (iVerilog)](http://iverilog.icarus.com/) — Open-source Verilog simulation and synthesis tool used to compile the RTL design and testbench.
* **Waveform Viewer:** [GTKWave](https://gtkwave.sourceforge.net/) — Fully featured wave viewer used to open and analyze the compiled `.vcd` (Value Change Dump) simulation files to verify the controller's state machine transitions.

## 🚀 Compilation and Simulation Guide

This workspace is fully optimized for VS Code utilizing the Icarus Verilog (iverilog) compiler toolchain and GTKWave for visual waveform debugging.

**Prerequisites**
Ensure you have the simulation binaries installed on your system terminal:

```text  
    # Verify installations
    iverilog -v
    vvp -v
```

## 💻Execution Steps

1. **Open your Terminal at the root project directory**  
2. **Compile the Design Modules Together**
3. **Execute the Compiled Binary**
4. **Analyze the Output Waveform**

```text
    # bash cmd
    iverilog -o sim_out.vvp rtl_design/direct_mapping.v testbench/testbench.v
    vvp sim_out.vvp
    gtkwave waveform/testbench.vcd
```
