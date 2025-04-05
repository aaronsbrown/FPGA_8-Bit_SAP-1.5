# Ben Eater 8-bit Computer (FPGA Implementation)

This project is a Verilog-based recreation of Ben Eater's classic breadboard 8-bit computer, implemented on an FPGA. The goal is to reproduce the original architecture faithfully — including the control logic, shared bus, and instruction cycle — and run programs with the same step-based execution model. Once the base version is working, the plan is to explore extensions that would be much harder to prototype with discrete TTL chips.

---

## 🧠 Project Goals

- Faithfully replicate Ben Eater's 8-bit CPU on an FPGA.
- Use Verilog/SystemVerilog to build each module (registers, ALU, RAM, control unit, etc.).
- Mirror the shared 8-bit bus architecture using multiplexers controlled by output enables.
- Simulate using Icarus Verilog + GTKWave.
- Load and execute simple machine code programs.
- Implement a microcoded control unit for extensible instruction handling.
- Standardize on synchronous design practices (clocking, reset).
- Later: explore extensions like stack support, more RAM, additional instructions, parameterization.
- Write a small Python-based assembler to support mnemonic instructions and simplify program authoring.

---

## 🧰 Hardware

- FPGA Board: Alchitry Cu (Lattice iCE40 HX)
- Expansion Board: Alchitry Io (optional for buttons, LEDs)
- No external RAM, just internal FPGA BRAM/logic blocks.

---

## 📂 Project Structure

```text
.
├── src/                  # All Verilog source modules
├── test/                 # Simulation testbenches
├── build/                # Output directory for VVP and waveform logs
├── constraints/          # Pin constraints for FPGA synthesis
├── docs/                 # Design notes, diagrams, analysis
├── fixture/              # Sample machine code programs (.hex)
├── scripts/              # Build and simulation scripts
└── README.md             # This file
```

---

## 🚦 Project Status

- [x] Project initialized
- [x] Bus + register structure defined
- [x] Consistent synchronous reset strategy implemented
- [x] ALU logic corrected for combinational flags / registered output
- [x] Instruction cycle FSM implemented
- [x] Program loading via `$readmemh` in simulation
- [x] Most core modules verified via simulation (registers, PC, RAM, ALU)
- [x] FPGA synthesis + LED output tested
- [x] Microcoded instruction execution verified (LDA, LDB, LDI, ADD, STA, JMP, OUTA, HLT)
- [x] FSM timing bug fixed with opcode stabilization step (`S_WAIT`)
- [ ] **Implement Flags Register** for state holding (major prerequisite for below)
- [ ] Implement `update_flags` control logic in microcode
- [ ] Implement and test conditional jumps (JZ, JC) using Flags Register
- [ ] Implement and test `CMP` instruction
- [ ] Add further tests for logic instructions (AND, OR)
- [ ] Add extended instruction set (e.g., INC, DEC)
- [ ] Add stack support and CALL/RET instructions

---

## 🔧 Simulation

To run a specific simulation testbench (e.g., the LDI test):

```bash
./scripts/simulate.sh --tb op_LDI_tb.sv
```
(Tests typically load their specific program into RAM using `$readmemh` from the `fixture/` directory).


🧪 **Test Strategy**

Each module is individually verified via simulation using Icarus Verilog and GTKWave before integrating into the full CPU. System-level tests verify instruction execution by running small programs loaded from `.hex` files and asserting expected register states.

🛠️ **Tools**
 * Icarus Verilog (Simulator)
 * GTKWave (Waveform Viewer)
 * sv2v (SystemVerilog to Verilog converter, used by scripts)
 * Yosys (Synthesis)
 * nextpnr (Place and Route for iCE40)
 * icepack/iceprog (Bitstream packing/uploading)

---

## 🛣️ Next Milestone: Conditional Logic & SAP-2 Features

With the core instruction cycle stable and ALU flags generating correctly (combinationally), the next critical step is implementing the **Flags Register** to properly latch and hold the C, Z, N status between instructions. This state-holding mechanism is essential for reliable conditional operations.

Once the Flags Register is implemented and controlled via microcode:
- Implement and test conditional jumps (`JZ`, `JC`).
- Implement and test a `CMP` instruction (Compare, affects flags like SUB).

Subsequent goals move toward a SAP-2-style architecture as described in Malvino's *Digital Computer Electronics*:
- Stack support via a dedicated stack pointer register.
- `CALL` and `RET` instructions for rudimentary subroutine support.
- Possibly expanding the RAM space or instruction width via parameterization.

These additions will allow the CPU to support more complex programs and branching logic.
