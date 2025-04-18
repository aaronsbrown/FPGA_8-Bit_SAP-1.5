`timescale 1ns/1ps
import test_utils_pkg::*;
import arch_defs_pkg::*;

module computer_tb;

  localparam string HEX_FILE = "../fixture/Flags_Reg_test_load_instructions.hex"; // Use final hex
  localparam EXPECTED_FINAL_OUTPUT = 8'h01; // Success code

  // --- Standard Testbench Setup ---
  reg clk;
  reg reset;
  wire [DATA_WIDTH-1:0] out_val;
  wire flag_zero_o, flag_carry_o, flag_negative_o;

  computer uut (
        .clk(clk), .reset(reset), .out_val(out_val),
        .flag_zero_o(flag_zero_o), .flag_carry_o(flag_carry_o), .flag_negative_o(flag_negative_o) );

  initial begin clk = 0; forever #5 clk = ~clk; end
  // --- End Standard Setup ---

  initial begin
    $dumpfile("waveform.vcd"); $dumpvars(0, computer_tb);
    $display("--- Loading hex file: %s ---", HEX_FILE);
    $readmemh(HEX_FILE, uut.u_ram.mem); uut.u_ram.dump();
    reset_and_wait(0);

    // --- LDI #0 --- (Ends C7)
    $display("Running LDI #0");
    repeat(7+1) @(posedge clk); #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h00, "A", DATA_WIDTH);
    pretty_print_assert_vec(flag_negative_o, 1'b0, "N after LDI #0");
    pretty_print_assert_vec(flag_carry_o,    1'b0, "C after LDI #0");
    pretty_print_assert_vec(flag_zero_o,     1'b1, "Z after LDI #0"); // Z=1
    inspect_register(uut.u_program_counter.counter_out, 8'h01, "PC", ADDR_WIDTH);

    // --- LDI #8 --- (Ends C14)
    $display("Running LDI #8");
    repeat(7) @(posedge clk); #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h08, "A", DATA_WIDTH);
    pretty_print_assert_vec(flag_negative_o, 1'b1, "N after LDI #8"); // N=1 (operand[3]=1)
    pretty_print_assert_vec(flag_carry_o,    1'b0, "C after LDI #8");
    pretty_print_assert_vec(flag_zero_o,     1'b0, "Z after LDI #8");
    inspect_register(uut.u_program_counter.counter_out, 8'h02, "PC", ADDR_WIDTH);

    // --- STA 0xE --- (Ends C23)
    $display("Running STA 0xE");
    repeat(9) @(posedge clk); #0.1;
    inspect_register(uut.u_ram.mem[14], 8'h08, "RAM[E]", DATA_WIDTH);
    pretty_print_assert_vec(flag_negative_o, 1'b1, "N after STA (no change)"); // From LDI #8
    pretty_print_assert_vec(flag_carry_o,    1'b0, "C after STA (no change)");
    pretty_print_assert_vec(flag_zero_o,     1'b0, "Z after STA (no change)");
    inspect_register(uut.u_program_counter.counter_out, 8'h03, "PC", ADDR_WIDTH);

    // --- LDI #0xF --- (Ends C30)
    $display("Running LDI #0xF");
    repeat(7) @(posedge clk); #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h0F, "A", DATA_WIDTH);
    pretty_print_assert_vec(flag_negative_o, 1'b1, "N after LDI #F"); // N=1 (operand[3]=1)
    pretty_print_assert_vec(flag_carry_o,    1'b0, "C after LDI #F");
    pretty_print_assert_vec(flag_zero_o,     1'b0, "Z after LDI #F");
    inspect_register(uut.u_program_counter.counter_out, 8'h04, "PC", ADDR_WIDTH);

    // --- STA 0xF --- (Ends C39)
    $display("Running STA 0xF");
    repeat(9) @(posedge clk); #0.1;
    inspect_register(uut.u_ram.mem[15], 8'h0F, "RAM[F]", DATA_WIDTH);
    pretty_print_assert_vec(flag_negative_o, 1'b1, "N after STA (no change)"); // From LDI #F
    pretty_print_assert_vec(flag_carry_o,    1'b0, "C after STA (no change)");
    pretty_print_assert_vec(flag_zero_o,     1'b0, "Z after STA (no change)");
    inspect_register(uut.u_program_counter.counter_out, 8'h05, "PC", ADDR_WIDTH);

    // --- LDA 0xE --- (Ends C48) -> Load 8 (0000 1000) -> Expect Flags={0,0,0}
    $display("Running LDA 0xE");
    repeat(9) @(posedge clk); #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h08, "A", DATA_WIDTH);
    pretty_print_assert_vec(flag_negative_o, 1'b0, "N after LDA 0xE"); // N=0 (bus[7]=0)
    pretty_print_assert_vec(flag_carry_o,    1'b0, "C after LDA 0xE");
    pretty_print_assert_vec(flag_zero_o,     1'b0, "Z after LDA 0xE");
    inspect_register(uut.u_program_counter.counter_out, 8'h06, "PC", ADDR_WIDTH);

    // --- LDB 0xF --- (Ends C57) -> Load F (0000 1111) -> Expect Flags={0,0,0}
    $display("Running LDB 0xF");
    repeat(9) @(posedge clk); #0.1;
    inspect_register(uut.u_register_B.latched_data, 8'h0F, "B", DATA_WIDTH);
    pretty_print_assert_vec(flag_negative_o, 1'b0, "N after LDB 0xF"); // N=0 (bus[7]=0)
    pretty_print_assert_vec(flag_carry_o,    1'b0, "C after LDB 0xF");
    pretty_print_assert_vec(flag_zero_o,     1'b0, "Z after LDB 0xF");
    inspect_register(uut.u_program_counter.counter_out, 8'h07, "PC", ADDR_WIDTH);

    // --- LDI #1 --- (Ends C64) -> Expect Flags={0,0,0}
    $display("Running LDI #1");
    repeat(7) @(posedge clk); #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h01, "A", DATA_WIDTH);
    pretty_print_assert_vec(flag_negative_o, 1'b0, "N after LDI #1");
    pretty_print_assert_vec(flag_carry_o,    1'b0, "C after LDI #1");
    pretty_print_assert_vec(flag_zero_o,     1'b0, "Z after LDI #1");
    inspect_register(uut.u_program_counter.counter_out, 8'h08, "PC", ADDR_WIDTH);

    // --- OUTA --- (Ends C71)
    $display("Running OUTA");
    repeat(7) @(posedge clk); #0.1;
    inspect_register(uut.u_register_OUT.latched_data, EXPECTED_FINAL_OUTPUT, "O after OUTA", DATA_WIDTH);
    inspect_register(uut.u_program_counter.counter_out, 8'h09, "PC", ADDR_WIDTH);

    // --- HLT --- (Ends C78)
    $display("Running HLT");
    run_until_halt(50);

    #0.1; $display("@%0t: Checking state after Halt", $time);
    pretty_print_assert_vec(uut.halt, 1'b1, "Halt signal active");
    inspect_register(uut.u_program_counter.counter_out, 8'h0A, "Final PC", ADDR_WIDTH);
    inspect_register(uut.u_register_OUT.latched_data, EXPECTED_FINAL_OUTPUT, "Final Output", DATA_WIDTH);

    $display("\033[0;32mLoad Flags test completed successfully.\033[0m");
    $finish;
  end

endmodule