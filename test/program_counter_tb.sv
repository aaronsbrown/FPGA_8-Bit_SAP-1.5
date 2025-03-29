`timescale 1ns / 1ps
`include "test_utilities.sv"

module program_counter_tb;
    logic clk;
    logic reset, enable, load;
    logic [3:0] counter_in;
    logic [3:0] counter_out;

    // Instantiate the DUT
    program_counter uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .load(load),
        .counter_in(counter_in),
        .counter_out(counter_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, program_counter_tb);

        // Initialize control signals
        reset = 1;
        enable = 0;
        load = 0;
        counter_in = 0;

        @(posedge clk);
        
        @(negedge clk);
        reset = 0;
        enable = 1;

        @(posedge clk);
        #1
        pretty_print_assert_vec(counter_out, 4'b0001, "Counter is 1");
        
        repeat (3) @(posedge clk);
        #1
        pretty_print_assert_vec(counter_out, 4'b0100, "Counter is 4");
       
        @(negedge clk);
        load = 1;
        counter_in = 4'b1010; // Load value 10

        
        @(posedge clk);
        #1
        pretty_print_assert_vec(counter_out, 4'b1010, "Counter loaded with 10");

        @(negedge clk);
        load = 0;
        
        @(posedge clk);
        #1    
        pretty_print_assert_vec(counter_out, 4'b1011, "Counter is 11 after load");

        @(negedge clk);
        reset = 1;
        
        @(posedge clk);
        #1    
        pretty_print_assert_vec(counter_out, 4'b0000, "Counter is 0 after reset");



        @(posedge clk);
        $display("RAM test complete at time %0t", $time);
        $finish;
    end

endmodule