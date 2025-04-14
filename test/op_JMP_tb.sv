`timescale 1ns/1ps
import test_utils_pkg::*;
import arch_defs_pkg::*;

module computer_tb;

  localparam string HEX_FILE = "../fixture/JMP.hex";

  reg clk;
  reg reset;
  wire [DATA_WIDTH-1:0] out_val;
  
  computer uut (
        .clk(clk),
        .reset(reset),
        .out_val(out_val)
    );

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

    reset_and_wait(0); // Finishes before edge starting C1

    $display("Running LDI #5");
    repeat(7 + 1) @(posedge clk); // Wait for edge ending C7
    #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h05, "After LDI: A", DATA_WIDTH);
    inspect_register(uut.u_program_counter.counter_out, 8'h01, "After LDI: PC", ADDR_WIDTH); // PC should be pointing to JMP instr
    
    $display("Running JMP 0xA");
    repeat(7) @(posedge clk); // Wait for edge ending C14
    #0.1;
    inspect_register(uut.u_program_counter.counter_out, 8'h0A, "After JMP: PC", ADDR_WIDTH);
    inspect_register(uut.u_register_A.latched_data, 8'h05, "After JMP: A", DATA_WIDTH);
    
    $display("Running HLT (ends C21)");
    run_until_halt(50); // Should halt around cycle 21

    #0.1;
    inspect_register(uut.u_program_counter.counter_out, 8'h0B, "After HLT: PC", ADDR_WIDTH); // PC increments during HLT fetch
    inspect_register(uut.u_register_A.latched_data, 8'h05, "After HLT: A", DATA_WIDTH);

    $display("\033[0;32mJMP instruction test completed successfully.\033[0m");
    $finish;
  end

endmodule