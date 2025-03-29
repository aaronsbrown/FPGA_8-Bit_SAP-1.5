module top (
    input clk,
    input rst_n,
    input usb_rx,
    output usb_tx,
    output [7:0] led
);
    
    computer u_computer (
        .clk(clk),
        .reset(~rst_n),
        .out_val(led)
    );

endmodule
