`timescale 1ns/1ps
import test_utils_pkg::*;
import arch_defs_pkg::*;

module computer_tb;

  localparam string HEX_FILE = "../fixture/JC.hex";

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
    inspect_register(uut.u_register_A.latched_data, 8'hFF, "After LDA [15]: A", DATA_WIDTH);
    inspect_register(uut.u_program_counter.counter_out, 8'h01, "After LDA #[15]: PC", ADDR_WIDTH);
    pretty_print_assert_vec(flag_zero_o, 1'b0, "After LDI #0: Z Flag"); 
    
    $display("Running ADD 0xE (should carry)");
    repeat(12) @(posedge clk); 
    inspect_register(uut.u_register_A.latched_data, 8'h00, "After ADD: A", DATA_WIDTH);
    inspect_register(uut.u_register_B.latched_data, 8'h01, "After ADD: B", DATA_WIDTH);
    pretty_print_assert_vec(flag_carry_o, 1'b1, "After ADD: C Flag"); 
    pretty_print_assert_vec(flag_zero_o, 1'b1, "After ADD: Z Flag"); 

    $display("Running JC 0x6 (should jump)");
    repeat(7) @(posedge clk); 
    #0.1;
    inspect_register(uut.u_program_counter.counter_out, 8'h06, "After JC 0x6: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h00, "After JC 0x6: A", DATA_WIDTH);
    
    $display("Running LDI #1");
    repeat(7) @(posedge clk); 
    #0.1;
    inspect_register(uut.u_program_counter.counter_out, 8'h07, "After LDI #1: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h01, "After LDI #1: A", DATA_WIDTH);
    pretty_print_assert_vec(flag_zero_o, 1'b0, "After LDI #1: Z Flag"); // Verify Z is clear
    
    $display("Running JC 0xA (should NOT jump)");
    repeat(7) @(posedge clk); 
    #0.1;
    $display("@%0t: Checking after JC 0xA completion edge", $time);
    inspect_register(uut.u_program_counter.counter_out, 8'h08, "After JC 0xA: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h01, "After JC 0xA: A", DATA_WIDTH);
    
    $display("Running OUTA");
    repeat(7) @(posedge clk); 
    #0.1;
    inspect_register(uut.u_register_o.latched_data, 8'h01, "After OUTA: O", DATA_WIDTH);
    inspect_register(uut.u_program_counter.counter_out, 8'h09, "After OUTA: PC", ADDR_WIDTH);
   
    
    $display("Running HLT");
    run_until_halt(50); 
    #0.1;
    $display("@%0t: Checking after Halt", $time);
    inspect_register(uut.u_program_counter.counter_out, 8'h0A, "After HLT: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h01, "After HLT: A", DATA_WIDTH);
    inspect_register(uut.u_register_o.latched_data, 8'h01, "After HLT: O", DATA_WIDTH);

    $display("\033[0;32mJC instruction test completed successfully.\033[0m");
    $finish;
  end

endmodule