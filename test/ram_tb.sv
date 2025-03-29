`timescale 1ns / 1ps
`include "test_utilities.sv"

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
        .oe(oe),
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
        oe = 0;
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

        // Wait one cycle
        @(posedge clk);

        // Read from address 0x3
        @(negedge clk);
        oe = 1;
        
        @(posedge clk);
        @(posedge clk);
        $display("Read data: %h (expected AB)", data_out);
        pretty_print_assert_vec(data_out, 8'hAB, "Data Out is hAB");
        
        @(negedge clk);
        oe = 0;
        
        @(posedge clk);

        
        @(negedge clk);
        address = 4'hA; // Write 0xCD to address 0xA
        data_in = 8'hCD;
        we = 1;
        
        @(posedge clk);
        
        @(negedge clk);
        we = 0;

        @(posedge clk);

        @(negedge clk);
        oe = 1;
        
        @(posedge clk);
        @(posedge clk);
        $display("Read data: %h (expected CD)", data_out);
        pretty_print_assert_vec(data_out, 8'hCD, "Data Out is hCD");

        @(negedge clk);
        oe = 0;

        $display("RAM test complete at time %0t", $time);
        $finish;
    end

endmodule