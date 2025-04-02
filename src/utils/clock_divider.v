module clock_divider #(
    parameter DIV_FACTOR = 50_000_000
) (
    input   wire    reset,
    input   wire    clk_in,
    output  reg    clk_out
);

    reg [25:0] counter;
    
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            counter <= counter + 1;
            if(counter == DIV_FACTOR - 1) begin
                clk_out <= ~clk_out;
                counter <= 0;
            end
        end
    end

endmodule