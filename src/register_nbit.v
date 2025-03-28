module register_nbit #(
    parameter N = 8
) (
    input             clk,
    input             reset,
    input             load,
    input    [N-1:0]  data_in,
    output  reg [N-1:0] latched_data
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            latched_data <= 0;
        end else if (load) begin
            latched_data <= data_in;
        end
    end

endmodule
