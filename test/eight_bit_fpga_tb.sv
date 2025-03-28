`timescale 1ns / 1ps

module eight_bit_fpga_tb;
    // Declare testbench signals

    // Instantiate the DUT
    eight_bit_fpga uut (
        // Port mappings
    );

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, eight_bit_fpga_tb);
        $display("Testbench works");
        $finish;
    end

    // initial begin
    //     $dumpfile("waveform.vcd");
    //     $dumpvars(0, eight_bit_fpga_tb);
        
    //     // Add testbench stimulus
    //     clk = 0;
    //     reset = 1;

    //     @(posedge clk);
    //     reset = 0;
        
    //     $display("Test complete at time %0t", $time);
    //     $finish;
    // end

endmodule
