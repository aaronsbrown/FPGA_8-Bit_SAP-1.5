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

More insights to come as the project evolves!
