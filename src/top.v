module top (
    input clk,
    input rst_n,
    output [7:0] led,
    output [2:0] io_led,
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

    wire [7:0] output_value;
    assign led = output_value;
    
    
    computer u_computer (
        .clk(clk_out),
        .reset(sys_reset),
        .out_val(output_value),
        .flag_zero_o(io_led[0]),    
        .flag_carry_o(io_led[1]),
        .flag_negative_o(io_led[2])
    );
    

    seg7_display u_display (
        .clk(clk_out),
        .reset(sys_reset),
        .number(output_value),
        .seg7( io_segment ),
        .select(io_select)
    );

endmodule
