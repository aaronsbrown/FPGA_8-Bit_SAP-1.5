`timescale 1ns/1ps
import test_utils_pkg::*;
import arch_defs_pkg::*;

module computer_tb;

  localparam string HEX_FILE = "../fixture/JN.hex";

  // --- Standard Testbench Setup ---
  reg clk;
  reg reset;
  wire [DATA_WIDTH-1:0] out_val;
  wire flag_zero_o, flag_carry_o, flag_negative_o; // Assuming these exist

  computer uut (
        .clk(clk),
        .reset(reset),
        .out_val(out_val),
        .flag_zero_o(flag_zero_o),
        .flag_carry_o(flag_carry_o),
        .flag_negative_o(flag_negative_o)
    );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  // --- End Standard Setup ---

  // Testbench stimulus
  initial begin
    
    $dumpfile("waveform.vcd");
    $dumpvars(0, computer_tb);

    $display("--- Loading hex file: %s ---", HEX_FILE);
    $readmemh(HEX_FILE, uut.u_ram.mem);
    uut.u_ram.dump();

    reset_and_wait(0); 
    
    $display("Running LDA xF");
    repeat(9+1) @(posedge clk); 
    #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h02, "After LDA [15]: A", DATA_WIDTH);
    inspect_register(uut.u_program_counter.counter_out, 8'h01, "After LDA #[15]: PC", ADDR_WIDTH);
    pretty_print_assert_vec(flag_zero_o, 1'b0, "After LDI #0: Z Flag"); 
    
    $display("Running SUB 0xE (should be negative)");
    repeat(12) @(posedge clk); 
    inspect_register(uut.u_register_A.latched_data, 8'hFD, "After SUB: A", DATA_WIDTH);
    inspect_register(uut.u_register_B.latched_data, 8'h05, "After SUB: B", DATA_WIDTH);
    pretty_print_assert_vec(flag_carry_o, 1'b0, "After SUB: C Flag"); 
    pretty_print_assert_vec(flag_zero_o, 1'b0, "After SUB: Z Flag"); 
    pretty_print_assert_vec(flag_negative_o, 1'b1, "After SUB: N Flag"); 

    $display("Running JN 0x6 (should jump)");
    repeat(7) @(posedge clk); 
    #0.1;
    inspect_register(uut.u_program_counter.counter_out, 8'h06, "After JN 0x6: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'hFD, "After JN 0x6: A", DATA_WIDTH);
    
    $display("Running LDI #8");
    repeat(7) @(posedge clk); 
    #0.1;
    inspect_register(uut.u_program_counter.counter_out, 8'h07, "After LDI #1: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h08, "After LDI #1: A", DATA_WIDTH);
    pretty_print_assert_vec(flag_zero_o, 1'b0, "After LDI #1: Z Flag"); // Verify Z is clear
    pretty_print_assert_vec(flag_negative_o, 1'b0, "After LDI: N Flag"); 

    $display("Running JN 0xA (should NOT jump)");
    repeat(7) @(posedge clk); 
    #0.1;
    $display("@%0t: Checking after JN 0xA completion edge", $time);
    inspect_register(uut.u_program_counter.counter_out, 8'h08, "After JN 0xA: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h08, "After JN 0xA: A", DATA_WIDTH);
    
    $display("Running STA");
    repeat(9) @(posedge clk); 
    inspect_register(uut.u_program_counter.counter_out, 8'h09, "After OUTM: PC", ADDR_WIDTH);

    $display("Running OUTM");
    repeat(9) @(posedge clk); 
    #0.1;
    inspect_register(uut.u_register_OUT.latched_data, 8'h08, "After OUTM: O", DATA_WIDTH);
    inspect_register(uut.u_program_counter.counter_out, 8'h0A, "After OUTM: PC", ADDR_WIDTH);
   
    $display("Running HLT");
    run_until_halt(50); 
    #0.1;
    $display("@%0t: Checking after Halt", $time);
    inspect_register(uut.u_program_counter.counter_out, 8'h0B, "After HLT: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h08, "After HLT: A", DATA_WIDTH);
    inspect_register(uut.u_register_OUT.latched_data, 8'h08, "After HLT: O", DATA_WIDTH);

    $display("\033[0;32mJN instruction test completed successfully.\033[0m");
    $finish;
  end

endmodule