`timescale 1ns / 1ps
import test_utils_pkg::*; 

module ram_tb;
    reg clk;
    reg we, oe;
    reg [3:0] address;
    reg [7:0] data_in;
    wire [7:0] data_out;

    // Instantiate the DUT
    ram uut (
        .clk(clk),
        .we(we),
        .address(address),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, ram_tb);

        // Initialize control signals
        we = 0;
        address = 4'b0000;
        data_in = 8'h00;

        // Wait for one clock cycle
        @(posedge clk);

        // control signals on negedge for setup time
        @(negedge clk);
        address = 4'h3;
        data_in = 8'hAB;
        we = 1;
        
        @(posedge clk);
        
        @(negedge clk);
        we = 0;

        // account for stability time
        @(posedge clk);

        @(posedge clk);
        $display("Read data: %h (expected AB)", data_out);
        pretty_print_assert_vec(data_out, 8'hAB, "Data Out is hAB");
        
        @(negedge clk);
        address = 4'hA; // Write 0xCD to address 0xA
        data_in = 8'hCD;
        we = 1;
        
        @(posedge clk);
        
        @(negedge clk);
        we = 0;

        // account for stability time
        @(posedge clk);
        
        @(posedge clk);
        $display("Read data: %h (expected CD)", data_out);
        pretty_print_assert_vec(data_out, 8'hCD, "Data Out is hCD");

        $display("RAM test complete at time %0t", $time);
        $finish;
    end

endmodule