`timescale 1ns/1ps
import test_utils_pkg::*; // Import test helpers
import arch_defs_pkg::*;  // Import architecture definitions (DATA_WIDTH, ADDR_WIDTH, etc.)

module computer_tb;

  // Define the program to load for this specific test
  localparam string HEX_FILE = "../fixture/HLT.hex";

  // --- Standard Testbench Signals ---
  reg clk;
  reg reset;
  wire [DATA_WIDTH-1:0] out_val;
  // Declare wires for flag outputs, even if not checked in this specific test,
  // if the 'computer' module defines them as outputs.
  wire flag_zero_o, flag_carry_o, flag_negative_o;

  // --- Instantiate the Device Under Test (DUT) ---
  computer uut (
        .clk(clk),
        .reset(reset),
        .out_val(out_val),
        // Connect flag outputs
        .flag_zero_o(flag_zero_o),
        .flag_carry_o(flag_carry_o),
        .flag_negative_o(flag_negative_o)
    );

  // --- Clock Generation ---
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns clock period (5ns low, 5ns high)
  end
  // --- End Standard Setup ---

  // --- Testbench Stimulus ---
  initial begin

    // Setup waveform dumping
    $dumpfile("waveform.vcd");
    $dumpvars(0, computer_tb); // Dump all signals in this module and below

    $display("--- Loading hex file: %s ---", HEX_FILE);
    $readmemh(HEX_FILE, uut.u_ram.mem); 
    uut.u_ram.dump(); 

    // Apply reset and wait for it to release
    reset_and_wait(0); // Finishes just before edge starting Cycle 1

    // --- Execute the HLT instruction ---
    // HLT is at Addr 0. Fetch C1-C5 (PC becomes 1). Exec C6-C7. Halts end C7.
    $display("Running HLT instruction (at Addr 0)");
    run_until_halt(50); // Waits for uut.halt == 1 signal

    // --- Checks After Halt ---
    #0.1;
    pretty_print_assert_vec(uut.halt, 1'b1, "Halt signal active");
    // Inlined expected value:
    inspect_register(uut.u_program_counter.counter_out, 32'd1, "PC after HLT fetch", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, {DATA_WIDTH{1'b0}}, "Register A after HLT", DATA_WIDTH);
    inspect_register(uut.u_register_OUT.latched_data, {DATA_WIDTH{1'b0}}, "Output Reg O after HLT", DATA_WIDTH);
    $display("\033[0;32mHLT instruction test completed successfully.\033[0m");
    $finish;
  end

endmodule