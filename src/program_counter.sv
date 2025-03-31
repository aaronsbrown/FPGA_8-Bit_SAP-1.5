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

    
     // Changed sensitivity list: trigger on posedge clk OR posedge reset
    always_ff @(posedge clk or posedge reset) begin
        // Check reset first (asynchronous)
        if (reset) begin // No need to wait for clock edge
            counter_out <= {ADDR_WIDTH{1'b0}};
        // If not resetting, check load/enable on the clock edge
        end else if (load) begin // Note: Removed 'posedge clk' check here, covered by sensitivity list
            counter_out <= counter_in;
        end else if (enable) begin
            counter_out <= counter_out + 1;
        end
        // If none of the above, implicitly hold value on posedge clk
    end


endmodule
