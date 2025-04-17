`timescale 1ns/1ps
import test_utils_pkg::*;
import arch_defs_pkg::*;

module computer_tb;

  localparam string HEX_FILE = "../fixture/JZ.hex";

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
    
    // --- LDI #0 ---
    $display("Running LDI #0");
    repeat(7+1) @(posedge clk); 
    #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h00, "After LDI #0: A", DATA_WIDTH);
    pretty_print_assert_vec(flag_zero_o, 1'b1, "After LDI #0: Z Flag"); // Verify Z is set
    inspect_register(uut.u_program_counter.counter_out, 8'h01, "After LDI #0: PC", ADDR_WIDTH);
    
    $display("Running JZ 0x5 (should jump)");
    repeat(7) @(posedge clk); 
    #0.1;
    $display("@%0t: Checking after JZ 0x5 completion edge", $time);
    inspect_register(uut.u_program_counter.counter_out, 8'h05, "After JZ 0x5: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h00, "After JZ 0x5: A", DATA_WIDTH);
    
    // --- LDI #1 (Fetched from address 0x5) ---
    $display("Running LDI #1");
    repeat(7) @(posedge clk); // Wait for edge ending C21
    #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h01, "After LDI #1: A", DATA_WIDTH);
    pretty_print_assert_vec(flag_zero_o, 1'b0, "After LDI #1: Z Flag"); // Verify Z is clear
    inspect_register(uut.u_program_counter.counter_out, 8'h06, "After LDI #1: PC", ADDR_WIDTH);
    
    // --- JZ 0x9 (Jump should NOT be taken) ---
    $display("Running JZ 0x9 (should NOT jump, ends C28)");
    repeat(7) @(posedge clk); // Wait for edge ending C28
    #0.1;
    $display("@%0t: Checking after JZ 0x9 completion edge", $time);
    // Check PC - should be 0x7 (incremented past JZ at 0x6)
    inspect_register(uut.u_program_counter.counter_out, 8'h07, "After JZ 0x9: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h01, "After JZ 0x9: A", DATA_WIDTH);
    
    // --- OUTA (Fetched from address 0x7) ---
    $display("Running OUTA");
    repeat(7) @(posedge clk); 
    #0.1;
    inspect_register(uut.u_register_OUT.latched_data, 8'h01, "After OUTA: O", DATA_WIDTH);
    inspect_register(uut.u_program_counter.counter_out, 8'h08, "After OUTA: PC", ADDR_WIDTH);
   
    // --- HLT (Fetched from address 0x8) ---
    $display("Running HLT (ends C42)");
    run_until_halt(50); // Should halt around cycle 42

    // Final check after halt
    #0.1;
    $display("@%0t: Checking after Halt", $time);
    inspect_register(uut.u_program_counter.counter_out, 8'h09, "After HLT: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h01, "After HLT: A", DATA_WIDTH);
    inspect_register(uut.u_register_OUT.latched_data, 8'h01, "After HLT: O", DATA_WIDTH);

    $display("\033[0;32mJZ instruction test completed successfully.\033[0m");
    $finish;
  end

endmodule