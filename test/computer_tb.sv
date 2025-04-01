`timescale 1ns / 1ps
`include "test_utilities.sv"

module computer_tb;
    // Declare testbench signals
    reg clk, reset;
    reg [7:0] out_val;

    // Instantiate the DUT
    computer uut (
        .clk(clk),
        .reset(reset),
        .out_val(out_val)
    );

    initial begin
        clk = 1;
        forever #5 clk = ~clk; // Generate a clock signal with a period of 10 time units
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, computer_tb);
        
        reset = 1;
        
        @(posedge clk); // 000
        reset = 0;
        

        repeat (12) begin
            @(posedge clk);
        end
        pretty_print_assert_vec(uut.u_register_A.latched_data, 8'h44, "A Reg is 0x44");

        repeat (12) begin
            @(posedge clk);
        end
        pretty_print_assert_vec(uut.u_register_B.latched_data, 8'h22, "B Reg is 0x22");

repeat (20) begin
            @(posedge clk);
        end

        $display("Test complete at time %0t", $time);
        $finish;
    end

endmodule
