# Implementation Approach: Ben Eater 8-bit Computer (FPGA)

This project recreates Ben Eater’s classic 8-bit breadboard computer using Verilog on an FPGA. The goal is to implement a faithful, modular, and testable version of the architecture, with simulation and hardware integration support.

---

## 🧭 Phase Approach

### **Phase 1: Architecture + Top-Level Wiring**

- Define `eight_bit_fpga.v` as the top-level integration module.
- Wire up all key modules:
  - Program Counter (`pc`)
  - Instruction Register (`ir`)
  - Memory Address Register (`mar`)
  - RAM (`ram`)
  - A Register (`a_reg`)
  - B Register (`b_reg`)
  - ALU (`alu`)
  - Output Register (`out`)
  - Control Unit (`control`)
  - Clock & Reset logic
  - Shared 8-bit bus between modules
- Stub out each module with just port definitions if not yet implemented.

---

### **Phase 2: Implement Individual Modules**

- Develop and test each subsystem independently:
  - Core Register Modules (`a_reg`, `b_reg`, `out`)
  - ALU: Simple arithmetic and logic ops
  - RAM: Read/write using address from `mar`, data via bus
  - Control Logic: Micro-instruction decoding and control word generation
  - Program Counter: Increment, jump, reset
  - Instruction Flow: IR loading and decoding
  - Clock Control: Manual and auto-clock toggling
  - Display Output: Hook `out` register to IO elements like LEDs or 7-segment display

---

### **Phase 3: Integration & Simulation**

- Wire everything through the shared bus in `eight_bit_fpga.v`
- Create a robust testbench for system-level verification
- Use simulation to confirm bus behavior and instruction execution
- Deploy to FPGA and validate with real hardware
- Run a sample program (e.g., increment and output loop)

---

## Notes

- All modules will be built incrementally and simulated individually before full integration.
- Project build and simulation are fully automated via `build.sh` and `simulate.sh`.
