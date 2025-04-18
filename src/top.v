module top (
    input clk,
    input rst_n,
    output [7:0]  led,
    output [23:0] io_led,
    output [6:0]  io_segment,
    output [3:0]  io_select
);
    
    // Derive 20MHz clock from 100MHz input
    wire clk_out, clk_div;
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
    assign io_led[23:16] = output_value;
    
    // TODO replace slow clock with a 'stepped' clock
    // clock_divider #(
    //     .DIV_FACTOR(1_200_000) // 20MHz clock from 100MHz input
    // ) u_clk_div (
    //     .clk_in(clk_out),
    //     .reset(sys_reset),
    //     .clk_out(clk_div)
    // );

    computer u_computer (
        .clk(clk_out),
        .reset(sys_reset),
        .out_val(output_value),
        .flag_zero_o(led[0]),    
        .flag_carry_o(led[1]),
        .flag_negative_o(led[2]),
        .debug_out_B(io_led[15:8]),
        .debug_out_IR(io_led[7:0]),
        .debug_out_PC(led[7:4])
    );
  
    // Assign the remaining LEDs to 0
    assign led[3] = 1'b0;
    
    seg7_display u_display (
        .clk(clk_out),
        .reset(sys_reset),
        .number(output_value),
        .seg7( io_segment ),
        .select(io_select)
    );

endmodule
