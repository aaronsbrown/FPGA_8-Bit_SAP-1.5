# FPGA Design: Field Notes & Insights

These notes capture key theoretical takeaways, mindset shifts, and FPGA-specific best practices encountered while implementing Ben Eater's 8-bit computer on an FPGA using Verilog.

---

## 🧠 Hardware Abstraction: Breadboard vs. FPGA

### Tri-State Buffers

- **Breadboard (TTL logic)**: Tri-state buffers physically disconnect their outputs using transistors (e.g. 74LS245), allowing safe sharing of a bus.
- **FPGA**: Internal tri-state buffers are not supported in the fabric. Instead, we simulate bus sharing using multiplexers or conditional logic at the **top level**.

> 💡 *"On a breadboard, OE disables transistors. In an FPGA, OE selects logic paths."*

---

### Bus Arbitration

- Shared buses are implemented via **conditional assignment**, not electrical disconnection.
- Example:

```verilog
assign bus = (a_out_en) ? a_out :
             (b_out_en) ? b_out :
             8'bz; // default high-impedance (for simulation clarity)
```

---

## 🧰 FPGA Design Abstraction Levels

| Level          | Description | Usage in This Project |
|----------------|-------------|------------------------|
| **Gate Level** | Individual logic gates (AND, OR, DFFs) | Seldom used directly; handled by synthesis |
| **RTL (Register Transfer Level)** | Describes how data moves between registers and logic blocks | ✅ Main focus of this project |
| **Behavioral** | High-level operations (`+`, `if`, `case`, etc.) | Used, but synthesized into RTL/gate-level netlists |

- At RTL, you're describing **intent and behavior**, not physical gate wiring.
- Synthesis tools (like Yosys) turn behavioral/RTL code into optimized gate-level implementations.

---

## 💬 Design Mindset Shift

- You're not replicating electrons or chips — you're architecting digital logic.
- Synthesis tools are *better than humans* at choosing efficient gates.
- Focus on **clear logic structure**, **control flow**, and **module boundaries** — the tools handle the gates.

---

## 📌 Practical Tips

- Always treat `reset` behavior clearly — synchronous vs asynchronous depends on target fabric/toolchain.
- Separate **combinational logic** from **sequential logic** for clarity and simulation.
- Use **testbenches** to simulate and validate modules independently before top-level integration.

---

---

## 🛠️ Debugging Journey & Key Discoveries

### 🧩 Initial Problem: RAM module debugging (synchronous read/write)

**Insight:** Testbench timing is critical. Changing signals immediately after `@(posedge clk)` can cause race conditions/delta-cycle issues in simulation.  
**Solution:** Adopted robust testbench practices: changing stimulus between clock edges using `@(negedge clk)` or small delays (`#1`) after the active edge.  
**Note:** `timescale` directive is essential for defining simulation time units; ensure it's present in the files seen by the simulator (fixed by adding `timescale.v`).

---

### ❌ Problem: CPU Program Counter (PC) stuck at 'x' state after reset

**Debugging:** Unit testing (`program_counter_tb.sv`) showed PC logic was sound. Issue only appeared in full `computer.sv` simulation.  
**Hypothesis Trail:** Ruled out uninitialized RAM. Investigated why synchronous reset wasn’t clearing the 'x' state at the first clock edge (`T=5ns`).  
**Insight (Simulation Artifact):** Simulators may struggle with many simultaneous events at startup, causing non-blocking updates from synchronous resets to fail.  
**Solution 1 (Workaround):** Added `initial counter_out = 0;` to force initialization.  
**Solution 2 (Adopted):** Switched to asynchronous reset (`always_ff @(posedge clk or posedge reset)`), ensuring reset activates at `T=0`.

**REAL SOLUTION: Clock was initialized to 0 in testbench, so was never high when the reset signal was high.Therefore the synchronous reset never occured.

---

### ❌ Problem: Control signals / `control_word` becoming 'x'

**Debugging:** Even with PC fixed, `control_word` (driven by a synchronous flop) failed to reset, corrupting all derived control signals.  
**Solution:** Changed all main registers (state machine, IR, A, B, MAR, Temp via `register_nbit`) to use asynchronous reset for simulation stability.

---

### ❌ Problem: IR loading `0x00` instead of `0x11` from RAM

**Debugging:** Analyzed bus timing vs. RAM output vs. IR load signal.  
**Insight (RAM Latency):** Synchronous RAM (`ram.v` with `data_out_reg`) has 1-clock-cycle read latency.  
**Timing Conflict:** `oe_ram` was asserted/de-asserted in same cycle that `load_ir` was high—IR sampled the bus just as RAM data disappeared.  
**Solution:** Extended `oe_ram` assertion across two microsteps (T2 and T3) to keep RAM data valid when IR loads. Applied this pattern to other transfers too.

---

## 🔬 Key Concepts & Theoretical Notes

### Synchronous vs. Asynchronous Resets

- Sync resets preferred for timing analysis but can fail at simulation startup.
- Async resets react immediately; useful for simulation clarity but may affect `Fmax`.

### Simulation vs. Hardware

- Simulation may misrepresent startup timing—hardware is reality.
- Async resets are a valid workaround if synthesizable and functionally equivalent.

### Hardware Latency

- Real components (like RAM) introduce delay.
- Control logic must account for cycle-based access, unlike breadboard circuits.

### Tri-State Buffers (`'bz'`) vs. Multiplexers

- Verilog `'bz'` + conditional logic models shared bus behavior.
- Synthesizers infer muxes for FPGA implementation—no internal tri-state support.

### Timing Constraints (.pcf / .sdc)

- Required for meaningful timing analysis.
- Use `set_frequency` to specify design goals.
- Without constraints, P&R tools only report what was achieved, not what was required.

### Timing-Driven P&R

- Open-source tools like `nextpnr-ice40` less aggressive than commercial tools.
- RTL-level optimizations are the primary lever for fixing timing violations.

### Buffering

- Used to mitigate high fanout delays (e.g., on reset).
- Implement using intermediate wires or explicit buffers—check timing reports first.

---

## 🧪 Practical Takeaways

- Write robust testbenches; avoid signal changes on active edges.
- Ensure all registers are either initialized or reliably reset.
- Unit test individual modules before system integration.
- Prefer consistent reset style (async = smoother simulation).
- Carefully trace signal lifetimes cycle-by-cycle, especially around bus access.
- Model latency explicitly; align control logic to component behavior.
- Always provide clock constraints and iterate based on timing reports.

---

### Synthesis Mindset (Under Hardware Abstraction or Design Mindset)

The key is describing *what* hardware you want, not *how* it executes step-by-step like software. The synthesizer infers the hardware (e.g., multiplexers for the bus) from your description. Focus on describing the parallel structures and their connections.

---

### Reset Strategy (Under Practical Tips or Key Concepts)

Choose *one* strategy (synchronous or asynchronous) and apply it consistently. Synchronous resets (`always_ff @(posedge clk) if (reset) ...`) are generally preferred for synthesis and timing analysis, glitch immunity. They require careful testbench stimulus (ensure reset is active *during* the clock edge, meeting setup/hold). Asynchronous resets (`always_ff @(posedge clk or posedge reset) ...`) are often simpler for simulation startup but can have timing implications (`Fmax`, potential metastability if deasserted near clock edge).

---

### Blocking (`=`) vs. Non-blocking (`<=`) (Under Practical Tips or Key Concepts)

- **`<=` (Non-blocking):** Use for assignments to registers/variables within clocked blocks (`always_ff`). Schedules the update to occur after all right-hand sides in the block are evaluated for the current time step. Models concurrent hardware updates correctly.
- **`=` (Blocking):** Use for variables within combinational blocks (`always_comb`) or for temporary variables within sequential blocks *before* they are assigned non-blockingly. Executes immediately and can affect subsequent lines within the same block. Using it for register assignments often leads to simulation errors or synthesis mismatches.

---

### Simulation Initialization (Under Practical Tips)

Use simulator system tasks like `$readmemh("filename.hex", uut.ram_instance.mem_array);` in testbench `initial` blocks to load RAM/ROM content efficiently, rather than manual assignments or non-standard `initial` blocks within the design module itself (unless specifically targeting synthesis ROM initialization).

---

### ALU Flags Behavior & Conditional Jumps (Under Debugging Journey)

**Debugging:** Conditional jumps (`JC`, `JZ`) wouldn't work correctly if they read delayed registered flags or the "live" combinational flags after ALU inputs had changed.
**Insight (CPU Architecture):** Flags (C, Z, N) must capture the status of the operation that *sets* them (e.g., ADD, SUB, CMP). Conditional jumps must *read this stored state*, not the live ALU output, as subsequent instructions might change ALU inputs.
**Solution/Requirement:**

1. Modify ALU to output **combinational** flags based on the current operation's result.
2. Keep a **registered** output for the ALU result itself (`latched_result`) to drive the bus stably.
3. Implement a dedicated **Flags Register** in the main CPU module (`computer.sv`).
4. Add an `update_flags` control signal to the microcode/control logic, asserted only by instructions that should modify flags.
5. The Flags Register latches the ALU's combinational flag outputs only when `update_flags` is active.
6. Conditional jump logic must read from the **Flags Register**.

---

### The Role of the Clock (Under Key Concepts)

- Discretizes time, creating cycles for synchronous operation.
- The clock **period** must be long enough for signals to propagate through the longest combinational logic path between registers and meet the setup time requirements of the destination register. This ensures data is stable before sampling.
- The active clock **edge** is the sampling instant when all registers capture their input values simultaneously, based on the calculations completed *between* the previous edge and the current one.
- Combinational logic computes *between* clock edges, preparing values for the next sampling edge. This synchronous methodology manages complexity and inherent physical delays in hardware.

---

### Registered RAM Output & BRAM Inference (Under Key Concepts - Hardware Latency)

- **Latency:** Real components like Block RAM (BRAM) often have registered outputs for better timing performance. Accessing data typically involves presenting the address in cycle N and receiving the corresponding data at the output in cycle N+1. Control logic and testbenches must account for this 1-cycle read latency.
- **Inference:** Specific Verilog coding styles (`always_ff` handling writes and reading into an internal register which is then assigned to the output) are needed to encourage synthesis tools (like Yosys) to infer dedicated BRAM blocks instead of less efficient LUT-based RAM, especially crucial for larger memory sizes planned for extensions.

---

### Combinational vs. Registered Flags (CPU Requirement) (Under Key Concepts)

- **ALU Output:** An ALU typically produces *combinational* flag outputs (C, Z, N) that reflect the result of the current inputs (`a_in`, `b_in`, `alu_op`) immediately (after gate delays).
- **CPU State:** The CPU's architectural flags (read by conditional jumps) must *hold* the state from the last instruction that was intended to modify them (e.g., ADD, SUB, CMP).
- **Implementation:** This requires a separate **Flags Register** within the CPU core. The ALU's combinational flag outputs feed into this register. A control signal (`update_flags`) determines when the Flags Register latches these values (only at the end of flag-setting instructions). Conditional jumps read the stable state from the Flags Register.

---

### Carry Flag Semantics (Subtraction) (Under Key Concepts)

- Hardware Subtraction: `A - B` is typically implemented using two's complement addition: `A + (~B + 1)`.
- Physical Carry Out: The actual carry-out bit generated by the adder during this operation indicates **NOT Borrow** status.
  - `Carry Out = 1` means `A >= B` (unsigned), no borrow needed.
  - `Carry Out = 0` means `A < B` (unsigned), a borrow was needed.
- Architectural 'C' Flag Choice:
  - **Option A (This Project):** C Flag = Raw Carry Out. `JC` after SUB/CMP means "Jump if A >= B".
  - **Option B (e.g., x86):** C Flag = Inverted Carry Out (Borrow). `JC` after SUB/CMP means "Jump if A < B".
- This project uses Option A, so documentation and assembly logic must reflect that `JC` tests for `>=` unsigned after subtraction/comparison.

---

### Parameterization & Packages (Under Key Concepts or Practical Takeaways)

- **Parameters:** (`parameter WIDTH = 8`) Allow creating reusable, configurable modules (e.g., registers, ALU, RAM of different sizes). Defined within a module using `#(...)` or passed during instantiation.
- **Packages:** (`package ... endpackage`) Provide a dedicated namespace for shared definitions (parameters, typedefs like enums/structs). Imported (`import pkg::*;`) instead of using `` ```include ``. Cleaner, prevents namespace collisions, better dependency management than `` ```include ``. Recommended for centralizing architecture definitions (data widths, address widths, instruction types, control word structs).

---

More insights to come as the project evolves!
