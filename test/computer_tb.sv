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
        clk = 0;
        forever #5 clk = ~clk; // Generate a clock signal with a period of 10 time units
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, computer_tb);
        
        reset = 1;
        
        @(posedge clk); // 000
        reset = 0;
        
        
        
        // pretty_print_assert_vec(uut.bus, 8'b0, "Bus is reset to h00");
        // pretty_print_assert_vec(uut.u_register_A.latched_data, 8'b0, "A register is h00");
        
        // // Load temp register with 8'b11111111 and output to bus
        // force uut.u_register_temp.latched_data = 8'h1C;
        
        // @(posedge clk); // 001
        // pretty_print_assert_vec(uut.bus, 8'hFF, "Bus is hFF");
        // pretty_print_assert_vec(uut.u_register_A.data_in, 8'hFF, "A register input is hFF");
        
        // @(posedge clk); // 002
        // pretty_print_assert_vec(uut.u_register_A.data_in, 8'h00, "A register input is h00");
        // pretty_print_assert_vec(uut.u_register_A.latched_data, 8'hFF, "A register output is hFF");
        // pretty_print_assert_vec(uut.bus, 8'h00, "Bus is h00");

        // @(posedge clk); // 003
        // pretty_print_assert_vec(uut.bus, 8'hFF, "Bus is hFF");

        // repeat (5) begin
        //     @(posedge clk);
        // end

        // release uut.u_register_temp.latched_data;
        $display("Test complete at time %0t", $time);
        $finish;
    end

endmodule
