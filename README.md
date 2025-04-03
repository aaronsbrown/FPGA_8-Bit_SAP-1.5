# Ben Eater 8-bit Computer (FPGA Implementation)

This project is a Verilog-based recreation of Ben Eater's classic breadboard 8-bit computer, implemented on an FPGA. The goal is to reproduce the original architecture faithfully — including the control logic, shared bus, and instruction cycle — and run programs with the same step-based execution model. Once the base version is working, the plan is to explore extensions that would be much harder to prototype with discrete TTL chips.

---

## 🧠 Project Goals

- Faithfully replicate Ben Eater's 8-bit CPU on an FPGA
- Use Verilog to build each module (registers, ALU, RAM, control unit, etc.)
- Mirror the shared 8-bit bus architecture with tri-state logic
- Simulate using Icarus Verilog + GTKWave
- Load and execute simple machine code programs
- Implement a microcoded control unit for extensible instruction handling
- Later: explore extensions like stack support, more RAM, or additional instructions
- Write a small Python-based assembler to support mnemonic instructions and simplify program authoring

---

## 🧰 Hardware

- FPGA Board: Alchitry Cu (Lattice iCE40 HX)
- Expansion Board: Alchitry Io (optional for buttons, LEDs)
- No external RAM, just internal FPGA logic blocks

---

## 📂 Project Structure

.
├── src/                  # All Verilog source modules
├── test/                 # Simulation testbenches
├── build/                # Output directory for VVP and waveform logs
├── constraints/          # Pin constraints for FPGA synthesis
├── docs/0_schematics/    # Reference schematics based on Ben Eater’s diagrams
├── scripts/              # Build and simulation scripts
└── README.md             # This file

---

## 🚦 Project Status

- [x] Project initialized
- [x] Bus + register structure defined
- [x] Instruction cycle implemented
- [x] Program loaded from RAM
- [x] All modules verified via simulation
- [x] FPGA synthesis + LED output tested
- [x] Microcoded instruction execution verified (LDA, ADD, STA, JMP, etc.)
- [x] FSM timing bug fixed with opcode stabilization step
- [ ] Conditional jumps (JZ, JC) implemented and tested
- [ ] Extended instruction set (e.g., CMP, INC, DEC)
- [ ] Stack support and CALL/RET instructions

---

## 🔧 Simulation

To run a simulation:

```bash
./scripts/simulate.sh --tb test/computer_tb.sv
```

🧪 Test Strategy

Each module will be individually verified via simulation using Icarus Verilog and GTKWave before integrating into the full CPU.

🛠️ Tools
 • Icarus Verilog
 • GTKWave
 • Yosys + nextpnr for synthesis

## 🛣️ Next Milestone: Toward SAP-2

With the core instruction cycle now stable and microcoded execution working, the next major goal is to extend the CPU toward a SAP-2-style architecture as described in Malvino's *Digital Computer Electronics*. Planned features include:

- Conditional jumps using flag registers (JZ, JC)
- A CMP instruction to compare values without modifying registers
- Stack support via a dedicated stack pointer register
- CALL and RET instructions for rudimentary subroutine support
- Possibly expanding the RAM space or instruction width

These additions will allow the CPU to support more complex programs and branching logic, and bring it closer to the full SAP-2 feature set.
