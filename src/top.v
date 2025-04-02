module top (
    input clk,
    input rst_n,
    output [7:0] led,
    output [1:0] io_led,
    output [6:0] io_segment,
    output [3:0] io_select
);
    
    // Derive 20MHz clock from 100MHz input
    wire clk_out;
    wire pll_locked;

    pll u_pll (
        .clock_in(clk),
        .clock_out(clk_out),
        .locked(pll_locked)
    );

    // Generate a system reset that remains active until both rst_n is high and the PLL is locked
    wire sys_reset;
    // sys_reset is active-high: asserted if external reset is active (rst_n is low) or PLL is not locked
    assign sys_reset = ~rst_n || ~pll_locked;

    reg [7:0] output_value;
    assign led = output_value;
    
    reg [1:0] flags;
    assign io_led = flags;
    computer u_computer (
        .clk(clk_out),
        .reset(sys_reset),
        .out_val(output_value),
        .cpu_flags(flags)
    );
    
    seg7_display u_display (
        .clk(clk_out),
        .reset(~rst_n),
        .number(output_value),
        .seg7( io_segment[6:0] ),
        .select(io_select)
    );

endmodule
