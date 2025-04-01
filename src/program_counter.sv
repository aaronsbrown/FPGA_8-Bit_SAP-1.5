module program_counter #(
    parameter ADDR_WIDTH = 4
) (
    input logic clk,
    input logic reset,
    input logic enable,
    input logic load,
    input  logic [ADDR_WIDTH-1:0] counter_in,
    output logic [ADDR_WIDTH-1:0] counter_out
);

    
    always_ff @(posedge clk) begin
        if (reset) begin // No need to wait for clock edge
            counter_out <= {ADDR_WIDTH{1'b0}};
        end else if (load) begin 
            counter_out <= counter_in;
        end else if (enable) begin
            counter_out <= counter_out + 1;
        end
    end


endmodule
