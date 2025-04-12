import arch_defs_pkg::*;

module register_nbit #(
    parameter N = DATA_WIDTH
) (
    input                   clk,
    input                   reset,
    input                   load,
    input           [N-1:0] data_in,
    output  logic   [N-1:0] latched_data
);

    always_ff @(posedge clk) begin
        if (reset) begin
            latched_data <= {(N){1'b0}};
        end else if (load) begin
            latched_data <= data_in;
        end
    end

endmodule
