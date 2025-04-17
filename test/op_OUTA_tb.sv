`timescale 1ns/1ps
import test_utils_pkg::*;
import arch_defs_pkg::*; 

module computer_tb;
  
  localparam string HEX_FILE = "../fixture/OUTA.hex";

  reg clk;
  reg reset;
  wire [DATA_WIDTH-1:0] out_val; // Output value from the DUT
  
  // Instantiate the DUT (assumed to be named 'computer')
  computer uut (
        .clk(clk),
        .reset(reset),
        .out_val(out_val),
    );

  // Clock generation: 10ns period (5ns high, 5ns low)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Testbench stimulus
  initial begin
    
    $dumpfile("waveform.vcd");
    $dumpvars(0, computer_tb);

    $display("--- Loading hex file: %s ---", HEX_FILE);
    $readmemh(HEX_FILE, uut.u_ram.mem);
    uut.u_ram.dump();
    
    reset_and_wait(0);
    
    inspect_register(uut.u_register_A.latched_data, 8'h00, "A", DATA_WIDTH);
    run_until_halt(50);
    inspect_register(uut.u_register_A.latched_data, 8'h09, "A", DATA_WIDTH);
    inspect_register(uut.u_register_OUT.latched_data, 8'h09, "A", DATA_WIDTH);

    
    $display("\033[0;32mOUTA instruction test completed successfully.\033[0m");
    $finish;
  end

endmodule