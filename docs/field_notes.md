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

More insights to come as the project evolves!
