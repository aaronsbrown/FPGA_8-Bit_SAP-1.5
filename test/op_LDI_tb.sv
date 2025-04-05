`timescale 1ns/1ps
import test_utils_pkg::*; // Import test utility tasks

module computer_tb;

  // Clock and reset signals
  reg clk;
  reg reset;
  wire [7:0] out_val; // Output value from the DUT
  
  
  // Declare program memory array at the module level
  logic [7:0] prog [0:15];
   
  // Instantiate the DUT (assumed to be named 'computer')
  computer uut (
        .clk(clk),
        .reset(reset),
        .out_val(out_val)
    );

  // Clock generation: 10ns period (5ns high, 5ns low)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Testbench stimulus
  initial begin
    
    integer i;
    
    // Dump VCD waveforms for debugging
    $dumpfile("waveform.vcd");
    $dumpvars(0, computer_tb);

    clear_ram(0, 15); 

    // Program
    prog[0] = 8'h88; // LDI: Load immediate value x08 into A
    prog[1] = 8'hFF; // HLT: halt

  
    // Load the program into RAM starting at address 0, program size 3 bytes.
    load_program(prog, 0, 3);
    uut.u_ram.dump();
    
    reset_and_wait(0);
    run_until_halt(50);
    
    inspect_register(uut.u_register_A.latched_data, 8'h08, "A");

    $display("\033[0;32mLDI instruction test completed successfully.\033[0m");
    $finish;
  end

endmodule