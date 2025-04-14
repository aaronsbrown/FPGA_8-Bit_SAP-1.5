`timescale 1ns/1ps
import test_utils_pkg::*;
import arch_defs_pkg::*; 

module computer_tb;
  
  localparam string HEX_FILE = "../fixture/STA.hex";

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
    
    // REG A == 0x00
    inspect_register(uut.u_register_A.latched_data, 8'h00, "initial state: A", DATA_WIDTH);
    
    // LDI: (5 + 2) = 7 cycles
    repeat (7) @(posedge clk); 
    
    // + 1 for latching A register
    repeat (1) @(posedge clk); 
    #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h03, "after LDI x03: A", DATA_WIDTH);

    // STA: (5 + 4) = 9 cycles
    repeat (9) @(posedge clk);
    #0.1;
    inspect_register(uut.u_ram.mem[15], 8'h03, "RAM[F] after STA", DATA_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h03, "A after STA", DATA_WIDTH);

    // LDI: (5 + 2) = 7 cycles
    repeat (7) @(posedge clk);
    #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h00, "after LDI x00: A", DATA_WIDTH);

    // LDA: (5 + 4) = 9 cycles
    repeat (9) @(posedge clk);
    #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h03, "after LDA xF: A", DATA_WIDTH);

    run_until_halt(50);

    
    $display("\033[0;32mSTA instruction test completed successfully.\033[0m");
    $finish;
  end

endmodule