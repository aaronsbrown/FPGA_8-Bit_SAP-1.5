module button_conditioner (
    input wire clk,
    input wire raw_button,
    output reg conditioned_button,
    output wire conditioned_button_edge
);

    parameter integer DEBOUNCE_THRESHOLD = 50000;
    parameter integer COUNTER_WIDTH = 16;

    reg sync_ff1;
    reg sync_ff2;
    
    reg debounced_state;
    reg [COUNTER_WIDTH-1:0] debounce_counter;
    reg conditioned_button_prev;
    
    // Two-stage synchronizer for the raw button signal
    always @(posedge clk) begin
        
        sync_ff1 <= raw_button;
        sync_ff2 <= sync_ff1;

    end

    // Debounce with counter
    always @(posedge clk) begin
        if (sync_ff2 != debounced_state) begin
            if (debounce_counter < DEBOUNCE_THRESHOLD) begin
                debounce_counter <= debounce_counter + 1;
            end else begin
                debounced_state <= sync_ff2;
                debounce_counter <= 0;
            end
        end else begin
            debounce_counter <= 0;
        end

        conditioned_button <= debounced_state;
    end
    
    always @(posedge clk) begin
        conditioned_button_prev <= conditioned_button;
    end
    
    assign conditioned_button_edge = conditioned_button && ~conditioned_button_prev;

endmodule
