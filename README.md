# Ben Eater 8-bit Computer (FPGA Implementation) - "SAP-1.5" Version

This project is a Verilog-based recreation and enhancement of Ben Eater's classic breadboard 8-bit computer, implemented on an FPGA. The goal was to reproduce the original architecture faithfully, then extend it with microcode, parameterization, a flags register, and a complete initial 16-instruction set including conditional branches.

This repository represents a stable, "frozen" version corresponding to these initial goals. Future work towards a SAP-2 architecture would likely occur in a separate project or branch.

---

## 🧠 Project Goals (Achieved in this Version)

- Replicate and extend Ben Eater's 8-bit CPU on an FPGA.
- Use Verilog/SystemVerilog to build each module (registers, ALU, RAM, control unit, etc.).
- Utilize SystemVerilog packages for centralized type and parameter definitions (`arch_defs_pkg`).
- Parameterize core architecture (DATA_WIDTH=8, ADDR_WIDTH=4).
- Implement a shared bus architecture using multiplexers controlled by output enables.
- Simulate using Icarus Verilog + GTKWave.
- Load and execute machine code programs from `.hex` files.
- Implement a microcoded control unit.
- Standardize on synchronous design practices (clocking, reset, non-blocking assignments).
- Implement a functional Flags Register (Z, N, C) and conditional jumps (JZ, JC, JN).
- Implement flag setting (Z, N) on Load instructions (LDA, LDB, LDI).

---

## 🧰 Hardware

- FPGA Board: Alchitry Cu (Lattice iCE40 HX)
- Expansion Board: Alchitry Io (optional for buttons, LEDs)
- No external RAM, just internal FPGA BRAM/logic blocks (using parameterized RAM module).

---

## 📂 Project Structure

```text
.
├── src/                  # All Verilog source modules
│   ├── core/             # Core definitions (arch_defs_pkg.sv)
│   ├── utils/            # Utility modules (display, clocking)
│   └── *.sv              # Main component modules (computer, alu, ram, etc.)
├── test/                 # Simulation testbenches (*_tb.sv, test_utils_pkg.sv)
├── build/                # Output directory for VVP and waveform logs
├── constraints/          # Pin constraints for FPGA synthesis (.pcf, .sdc)
├── docs/                 # Design notes, diagrams, analysis
├── fixture/              # Sample machine code programs (.hex)
├── scripts/              # Build and simulation scripts
└── README.md             # This file
```

---

## ✅ Final Project Status ("SAP-1.5")

- [x] Project initialized & basic structure defined.
- [x] Core parameters (`DATA_WIDTH`, `ADDR_WIDTH`) and types (`opcode_t`, `control_word_t`, etc.) centralized in `arch_defs_pkg`.
- [x] Modules parameterized (`computer`, `alu`, `ram`, `register_nbit`, `program_counter`, `register_instruction`).
- [x] Bus + register structure implemented.
- [x] Consistent synchronous reset strategy implemented.
- [x] Correct use of non-blocking assignments (`<=`) in sequential blocks.
- [x] ALU logic implemented for ADD, SUB, AND, OR; outputs combinational flags (Z, N, C) and registered result. Correct C flag (Not Borrow) semantics for SUB.
- [x] **Flags Register (`u_register_flags`) implemented** in `computer.sv` to hold Z, C, N state.
- [x] **`load_flags` control mechanism implemented:** Bit added, microcode sets for ADD, SUB, AND, OR, LDA, LDB, LDI. Z/N flags correctly set based on ALU result or loaded value.
- [x] Instruction cycle FSM implemented with combinational control signal generation.
- [x] Program loading via `$readmemh` in simulation implemented and used in testbenches.
- [x] RAM module structured for synchronous operation (registered output) and BRAM inference.
- [x] All core modules individually verified via simulation.
- [x] FPGA synthesis + LED output tested.
- [x] **Full 16-instruction set verified** via simulation:
    - `NOP`, `LDA`, `LDB`, `ADD`, `SUB`, `AND`, `OR`, `STA`, `LDI`, `JMP`, `JC`, `JZ`, `JN`, `OUTM`, `OUTA`, `HLT`
- [x] **Conditional Jump FSM logic implemented and tested** (JZ, JC, JN working).
- [x] Testbench simulation timing corrected to observe results accurately after completion edges.
- [x] Successfully implemented CPU exceeds basic Ben Eater design capabilities.

---

## 🔧 Simulation

To run a specific simulation testbench (e.g., the Jump if Zero test):

```bash
./scripts/simulate.sh --tb op_JZ_tb.sv
```
(Tests typically load their specific program into RAM using `$readmemh` from the `fixture/` directory).

🧪 **Test Strategy**

Each module was individually verified. System-level tests verify instruction execution by running small programs loaded from `.hex` files and asserting expected register and flag states at precise clock cycles corresponding to instruction completion.

🛠️ **Tools**
 * Icarus Verilog (Simulator)
 * GTKWave (Waveform Viewer)
 * sv2v (SystemVerilog to Verilog converter, used by scripts)
 * Yosys (Synthesis)
 * nextpnr (Place and Route for iCE40)
 * icepack/iceprog (Bitstream packing/uploading)

---

## 🏛️ Achieved Architecture ("SAP-1.5") Summary

This version represents a significant step beyond the basic Ben Eater breadboard computer, incorporating features commonly found on the path towards SAP-2:

*   **Microcoded Control:** Flexible control unit using a microcode ROM.
*   **Parameterization:** Core data (8-bit) and address (4-bit) widths defined centrally.
*   **Synchronous Design:** Consistent clocking and reset methodology.
*   **Flags Register:** Dedicated register holding Zero (Z), Carry (C), and Negative (N) flags.
*   **Flag Setting:** ALU operations (ADD, SUB, AND, OR) and Load operations (LDA, LDB, LDI) correctly update Z and N flags. Carry flag correctly reflects carry/not-borrow.
*   **Full 4-bit Opcode Space Utilized:** Complete 16-instruction set implemented and tested:
    *   Data Transfer: `LDA`, `LDB`, `LDI`, `STA`
    *   Arithmetic: `ADD`, `SUB`
    *   Logic: `AND`, `OR` (*XOR pending*)
    *   Control Flow: `JMP`, `JZ`, `JC`, `JN`, `HLT`
    *   Output: `OUTA`, `OUTM`
    *   Other: `NOP`
*   **Conditional Branching:** Functional `JZ`, `JC`, `JN` based on the registered flags.

This forms a solid foundation but lacks features required for more complex software, primarily subroutine support.

---

## 🚀 Future Work / Toward SAP-2

This repository is considered feature-complete for its "SAP-1.5" goals. Further development towards a full SAP-2 architecture would involve:

1.  **Opcode Space Expansion:** The 4-bit opcode limit is reached. Requires moving to:
    *   **Multi-Byte Instructions:** Fetching 2 or 3 bytes for instructions needing immediate data or 16-bit addresses (most likely path). This significantly complicates the fetch/decode FSM.
    *   *Or* Wider `DATA_WIDTH`: Expanding the data bus/memory width (e.g., to 16 bits) to accommodate larger opcodes/operands in a single fetch.
2.  **Stack Implementation:**
    *   Add a Stack Pointer (`SP`) register.
    *   Implement `PUSH` / `POP` instructions *or* embed stack operations within `CALL`/`RET`.
3.  **Subroutine Instructions:**
    *   Implement `CALL` (pushes PC, jumps) and `RET` (pops PC).
4.  **Additional Instructions:**
    *   `XOR` (Logical)
    *   `CMP` (Compare - like SUB but only sets flags)
    *   `INC` / `DEC` (Increment/Decrement, decide flag behavior)
    *   Shift / Rotate instructions (`SHL`/`SAL`, `SHR`/`SAR`, `ROL`, `ROR`)
    *   `IN` (Input from external source)
5.  **Wider Address Bus:** Parameterize and increase `ADDR_WIDTH` to 8 (or 16 for SAP-2's typical 64KB space) to allow larger programs/data.
6.  **Robust Synthesis RAM Init:** Improve `ram.sv` `initial` block (e.g., using `$readmemh`) for reliable synthesis initialization across different parameters.
7.  **Assembler:** Develop the planned Python assembler.

These steps would bring the design much closer to a SAP-2 or comparable 8-bit microprocessor architecture.
