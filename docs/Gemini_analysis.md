Missing Flags Register: As identified in our chat, the central Flags Register is still missing from computer.sv.

The ALU outputs (flag_zero, flag_carry) are directly assigned to cpu_flags.

There's no mechanism (like an update_flags control signal and register) to latch the flags only when specific instructions (ADD, SUB, CMP, maybe others) complete.

The conditional jump logic (else if ( (next_control_word.check_zero && !flag_zero) ...) is still commented out and, more importantly, would read the live ALU flags, not the latched flags from the relevant previous instruction.

Action Needed:

Define the flag registers (e.g., logic C_reg, Z_reg;).

Add an update_flags bit to control_word_t.

Create an always_ff block for the flag registers, sensitive to clk, reset, and update_flags.

Modify the microcode: Set update_flags=1 for instructions like ADD, SUB. Set update_flags=0 for LDA, STA, JMP, etc. (unless you explicitly decide LDA/LDB should affect Z/N flags).

Modify the conditional jump logic to check C_reg and Z_reg instead of flag_carry and flag_zero.

Connect C_reg, Z_reg to the cpu_flags output port.
