`timescale 1ns/1ps
import test_utils_pkg::*;
import arch_defs_pkg::*; 

module computer_tb;
  
  localparam string HEX_FILE = "../fixture/Flags_Reg_OR.hex";

  reg clk;
  reg reset;
  wire flag_zero, flag_carry, flag_negative;
  wire [DATA_WIDTH-1:0] out_val; // Output value from the DUT
  
  // Instantiate the DUT (assumed to be named 'computer')
  computer uut (
        .clk(clk),
        .reset(reset),
        .out_val(out_val),
        .flag_zero_o(flag_zero),
        .flag_carry_o(flag_carry),
        .flag_negative_o(flag_negative)
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
    inspect_register(uut.u_register_A.latched_data, 8'h00, "initial state: A is 0", DATA_WIDTH);
    
    // LDA: (5 + 4) = 9 cycles
    repeat (9) @(posedge clk); 
   
    // + 1 for latching A register
    repeat (1) @(posedge clk); 
    #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'hF0, "after LDA: A is F0", DATA_WIDTH);

    // OR: (5 + 6) = 11
    repeat (11) @(posedge clk);
    #0.1; 
    inspect_register(uut.u_register_A.latched_data, 8'hFF, "after OR: A is 0", DATA_WIDTH);
    inspect_register(uut.u_register_B.latched_data, 8'h0F, "after OR: B is 1", DATA_WIDTH);
    pretty_print_assert_vec(flag_zero, 1'b0, "Flag Zero");
    pretty_print_assert_vec(flag_carry, 1'b0, "Flag Carry");
    pretty_print_assert_vec(flag_negative, 1'b1, "Flag Negative");

    run_until_halt(50);

    $display("\033[0;32mOR instruction test completed successfully.\033[0m");
    $finish;
  end

endmodule